/*
 * DistQLDPC web demo — page logic (no framework). Runs each computation in a fresh Web Worker (worker.js), shows the
 * bound events of src/core/dq_api.h live, and the final distance with a verified witness.
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
'use strict';

const $ = (id) => document.getElementById(id);
const DEFAULT_RULES = ['excl', 'pack', 'orbf', 'parity', 'leaf', 'overlap'];
const LOG_MAX = 20000;

const S = {
  index: [],
  version: null,
  code: null,          // bundled code JSON (sparse rows) or null in "own" mode
  mode: 'bundled',
  run: null,           // current / last run state
};

/* ---------- helpers ---------- */
function fmtSec(s) {
  if (s === null || s === undefined || isNaN(s)) return '–';
  if (s < 1) return (s * 1000).toFixed(0) + ' ms';
  if (s < 100) return s.toFixed(2) + ' s';
  return s.toFixed(0) + ' s';
}
function fmtInt(x) { return Number(x).toLocaleString('en-US'); }
function sparseToText(rows, n) {
  const out = new Array(rows.length);
  const z = '0'.repeat(n);
  for (let r = 0; r < rows.length; r++) {
    const a = z.split('');
    for (const c of rows[r]) a[c] = '1';
    out[r] = a.join('');
  }
  return out.join('\n') + '\n';
}
function textToSparse(txt) {
  const rows = [];
  let n = -1;
  for (const line of txt.split(/\r?\n/)) {
    const s = line.trim();
    if (!s || s[0] === '#') continue;
    const row = [];
    let c = 0;
    for (const ch of s) {
      if (ch === '0') c++;
      else if (ch === '1') { row.push(c); c++; }
    }
    if (c === 0) continue;
    if (n < 0) n = c;
    rows.push(row);
  }
  return { rows, n };
}
function download(name, text) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([text], { type: 'text/plain' }));
  a.download = name;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
}
function engineValue() { return document.querySelector('input[name=engine]:checked').value; }

/* ---------- options -> CLI flags ---------- */
function buildFlags() {
  const f = [];
  if (engineValue() === 'cc') {
    f.push('-engine=cc');
    const rules = [...document.querySelectorAll('.rule')].filter((x) => x.checked).map((x) => x.value);
    const same = rules.length === DEFAULT_RULES.length && DEFAULT_RULES.every((r) => rules.includes(r));
    if (!same) f.push('-cc-rules=' + (rules.length ? rules.join(',') : 'none'));
    if (!$('ccDual').checked) f.push('-cc-dual=off');
    if (!$('ubSearch').checked) f.push('-ub-search=off');
    if (!$('ubBasis').checked) f.push('-ub-basis=off');
  } else if (!$('ubPre').checked) {
    f.push('-ub-pre=off');
  }
  if (!$('symbreak').checked) f.push('-no-symbreak');
  const seed = parseInt($('seed').value, 10);
  if (seed > 0) f.push('-seed=' + seed);
  const lim = Math.max(1, parseInt($('timeLim').value, 10) || 120);
  f.push('-cpu-lim=' + lim);
  if ($('verbose').checked) f.push('-v');
  return f.join(' ');
}
function refreshOptions() {
  const cc = engineValue() === 'cc';
  $('ccOpts').hidden = !cc;
  $('msOpts').hidden = cc;
  document.querySelectorAll('input[name=engine]').forEach((r) => r.parentElement.classList.toggle('on', r.checked));
  $('flagsPreview').textContent = buildFlags();
  refreshHint();
}

/* ---------- code selection ---------- */
function codeLabel(c) {
  const d = c.d !== null ? 'd=' + c.d : 'd unknown';
  return `${c.stem}  (n=${c.n}, k=${c.k}, ${d})`;
}
function refreshHint() {
  const c = S.index.find((x) => x.stem === $('codeSel').value);
  if (!c) return;
  const t = c.timing || {};
  const parts = [`tier ${c.tier}`, c.bb ? `bivariate bicycle, torus ${c.bb.l} × ${c.bb.m}` : c.family];
  if (t.cc !== undefined || t.maxsat !== undefined) {
    parts.push('native (1 core, yfclab2): ' + [t.maxsat !== undefined ? 'MaxSAT ' + fmtSec(t.maxsat) : null,
      t.cc !== undefined ? 'CC ' + fmtSec(t.cc) : null].filter(Boolean).join(', '));
  }
  if (c.tier === 5 && engineValue() === 'maxsat' && t.maxsat === undefined) parts.push('MaxSAT did not solve this code in 6 h natively; use CC');
  else if (c.tier >= 3 && engineValue() === 'maxsat') parts.push('MaxSAT may need minutes to hours here; CC is much faster');
  if (engineValue() === 'cc' && t.cc !== undefined && t.cc > 300) parts.push('long run: keep this tab in the foreground');
  $('codeHint').textContent = parts.join(' · ');
}
// time limit suggested for the selected code and engine: 3x the native time, at least 120 s (max 24 h)
function suggestLimit() {
  const c = S.index.find((x) => x.stem === $('codeSel').value);
  const t = (c && c.timing) || {};
  const nat = t[engineValue()];
  const lim = nat !== undefined ? Math.min(86400, Math.max(120, Math.ceil(nat * 3 / 60) * 60)) : (c && c.tier >= 4 ? 3600 : 120);
  $('timeLim').value = lim;
}
async function loadIndex() {
  try {
    const r = await fetch('codes/index.json');
    S.index = await r.json();
  } catch (e) {
    S.index = [];
    $('codeHint').textContent = 'codes/index.json not found (run web/build.sh)';
  }
  const sel = $('codeSel');
  const tiers = [...new Set(S.index.map((c) => c.tier))].sort();
  for (const t of tiers) {
    const g = document.createElement('optgroup');
    g.label = t === 5 ? 'tier 5 (large; solved by CC in seconds to hours)' : `tier ${t}`;
    for (const c of S.index.filter((x) => x.tier === t)) {
      const o = document.createElement('option');
      o.value = c.stem;
      o.textContent = codeLabel(c);
      g.appendChild(o);
    }
    sel.appendChild(g);
  }
  if (S.index.find((c) => c.stem === 'BB_72_12_6')) sel.value = 'BB_72_12_6';
  refreshHint();
}
async function getCode(stem) {
  const r = await fetch('codes/' + stem + '.json');
  if (!r.ok) throw new Error('cannot load codes/' + stem + '.json');
  return r.json();
}
function setMode(m) {
  S.mode = m;
  $('modeBundled').classList.toggle('on', m === 'bundled');
  $('modeOwn').classList.toggle('on', m === 'own');
  $('modeBundled').setAttribute('aria-selected', m === 'bundled');
  $('modeOwn').setAttribute('aria-selected', m === 'own');
  $('bundledBox').hidden = m !== 'bundled';
  $('ownBox').hidden = m !== 'own';
}

/* ---------- log ---------- */
const logEl = $('log');
let logLines = 0;
function logAppend(lines, cls) {
  const frag = document.createDocumentFragment();
  for (const l of lines) {
    const s = document.createElement('span');
    if (cls) s.className = cls;
    s.textContent = l + '\n';
    frag.appendChild(s);
  }
  const stick = logEl.scrollTop + logEl.clientHeight >= logEl.scrollHeight - 30;
  logEl.appendChild(frag);
  logLines += lines.length;
  while (logLines > LOG_MAX && logEl.firstChild) { logEl.removeChild(logEl.firstChild); logLines--; }
  if (stick) logEl.scrollTop = logEl.scrollHeight;
}
function logClear() { logEl.textContent = ''; logLines = 0; }

/* ---------- chart (two step series over time, one y axis) ---------- */
const svg = $('chart');
const NS = 'http://www.w3.org/2000/svg';
function el(tag, attrs, parent) {
  const e = document.createElementNS(NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (parent) parent.appendChild(e);
  return e;
}
function niceStep(range, target) {
  const raw = range / target;
  const p = Math.pow(10, Math.floor(Math.log10(raw)));
  for (const m of [1, 2, 5, 10]) if (m * p >= raw) return m * p;
  return 10 * p;
}
function runNow(R) { return R.end !== null ? R.end : (performance.now() - R.t0) / 1000; }
function valueAt(pts, t) {
  let v = null;
  for (const p of pts) { if (p.t <= t) v = p.v; else break; }
  return v;
}
let chartGeom = null;
function drawChart() {
  const R = S.run;
  const W = svg.clientWidth || 600, H = svg.clientHeight || 260;
  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
  svg.textContent = '';
  const m = { l: 34, r: 14, t: 10, b: 26 };
  const iw = W - m.l - m.r, ih = H - m.t - m.b;
  const tmax = R ? Math.max(runNow(R), 0.5) : 10;
  let ymax = 8;
  if (R) {
    for (const p of R.lb) ymax = Math.max(ymax, p.v);
    for (const p of R.ub) ymax = Math.max(ymax, p.v);
    if (R.expected) ymax = Math.max(ymax, R.expected);
  }
  ymax = Math.ceil(ymax * 1.08) + 1;
  const x = (t) => m.l + (t / tmax) * iw;
  const y = (v) => m.t + ih - (v / ymax) * ih;
  const ys = niceStep(ymax, 5), xs = niceStep(tmax, 6);
  for (let v = 0; v <= ymax + 1e-9; v += ys) {
    el('line', { x1: m.l, x2: m.l + iw, y1: y(v), y2: y(v), class: 'gridl' }, svg);
    el('text', { x: m.l - 6, y: y(v) + 4, 'text-anchor': 'end' }, svg).textContent = v;
  }
  for (let t = 0; t <= tmax + 1e-9; t += xs) {
    el('text', { x: x(t), y: H - 8, 'text-anchor': 'middle' }, svg).textContent =
      (xs < 1 ? t.toFixed(xs < 0.1 ? 2 : 1) : t.toFixed(0)) + (t === 0 ? '' : ' s');
  }
  chartGeom = { m, iw, ih, x, y, tmax };
  if (!R) return;
  if (R.expected) {
    el('line', { x1: m.l, x2: m.l + iw, y1: y(R.expected), y2: y(R.expected), class: 'ref' }, svg);
    el('text', { x: m.l + iw - 2, y: y(R.expected) - 4, 'text-anchor': 'end' }, svg).textContent = 'd in stem = ' + R.expected;
  }
  const now = runNow(R);
  for (const [pts, cls] of [[R.lb, 'lbl'], [R.ub, 'ubl']]) {
    if (!pts.length) continue;
    let d = `M${x(pts[0].t).toFixed(1)} ${y(pts[0].v).toFixed(1)}`;
    for (let i = 1; i < pts.length; i++) d += ` H${x(pts[i].t).toFixed(1)} V${y(pts[i].v).toFixed(1)}`;
    d += ` H${x(now).toFixed(1)}`;
    el('path', { d, class: 'ser ' + cls }, svg);
    const last = pts[pts.length - 1];
    el('circle', { cx: x(now), cy: y(last.v), r: 4, class: 'dot', fill: cls === 'lbl' ? 'var(--lb)' : 'var(--ub)' }, svg);
  }
}
function chartHover(ev) {
  const R = S.run;
  const tip = $('tip');
  if (!R || !chartGeom || (!R.lb.length && !R.ub.length)) { tip.hidden = true; return; }
  const rect = svg.getBoundingClientRect();
  const px = ev.clientX - rect.left;
  const { m, iw, x, y, tmax } = chartGeom;
  if (px < m.l || px > m.l + iw) { tip.hidden = true; drawChart(); return; }
  const t = Math.min(runNow(R), ((px - m.l) / iw) * tmax);
  drawChart();
  const lb = valueAt(R.lb, t), ub = valueAt(R.ub, t);
  el('line', { x1: x(t), x2: x(t), y1: m.t, y2: m.t + chartGeom.ih, class: 'xh' }, svg);
  if (lb !== null) el('circle', { cx: x(t), cy: y(lb), r: 4, class: 'dot', fill: 'var(--lb)' }, svg);
  if (ub !== null) el('circle', { cx: x(t), cy: y(ub), r: 4, class: 'dot', fill: 'var(--ub)' }, svg);
  tip.innerHTML = `<div>t = ${fmtSec(t)}</div>` +
    `<div><span class="k" style="background:var(--lb)"></span>d<sub>lb</sub> ${lb === null ? '–' : lb}</div>` +
    `<div><span class="k" style="background:var(--ub)"></span>d<sub>ub</sub> ${ub === null ? '–' : ub}</div>`;
  tip.hidden = false;
  const left = Math.min(px + 12, rect.width - tip.offsetWidth - 4);
  tip.style.left = left + 'px';
  tip.style.top = '8px';
}

/* ---------- table ---------- */
function setTable(kind) {
  const head = $('tbl').querySelector('thead');
  const cols = kind === 'cc'
    ? ['#', 'half', 'weight w', 'verdict', 'nodes', 'time']
    : ['#', 'half', 'cap', 'probe', 'verdict', 'value', 'conflicts', 'time'];
  head.innerHTML = '<tr>' + cols.map((c, i) => `<th class="${i === 1 || (kind !== 'cc' && i === 3) ? 'l' : ''}">${c}</th>`).join('') + '</tr>';
  $('tbl').querySelector('tbody').textContent = '';
  $('tblTitle').textContent = kind === 'cc' ? 'CC weight levels' : 'MaxSAT probes';
  $('tblHint').textContent = kind === 'cc'
    ? 'EMPTY level w: no logical of weight w in that half'
    : 'feasibility: is there a logical of weight ≤ cap? optimize: the minimum below cap';
}
function addRow(cells, verdictIdx) {
  const tb = $('tbl').querySelector('tbody');
  const tr = document.createElement('tr');
  cells.forEach((c, i) => {
    const td = document.createElement('td');
    td.textContent = c;
    if (i === 1 || (cells.length === 8 && i === 3)) td.className = 'l';
    if (i === verdictIdx) td.className = 'l v-' + c;
    tr.appendChild(td);
  });
  tb.appendChild(tr);
  const w = tb.parentElement.parentElement;
  w.scrollTop = w.scrollHeight;
}

/* ---------- witness ---------- */
function witnessParity(R, w) {
  // H e = 0 recomputed in the page (X half: Hz, Z half: Hx); the engine already checked it and the nontriviality
  const H = w.half === 'X' ? R.Hz : R.Hx;
  if (!H) return null;
  const s = new Set(w.support);
  for (const row of H) {
    let p = 0;
    for (const c of row) if (s.has(c)) p ^= 1;
    if (p) return false;
  }
  return true;
}
function showWitness() {
  const R = S.run;
  const w = R && R.best;
  const box = $('torus');
  box.textContent = '';
  if (!w) {
    $('wInfo').textContent = 'A minimum-weight logical operator appears here when the search finds one.';
    $('wDl').disabled = true;
    return;
  }
  const typ = w.half === 'X' ? 'X-type logical x (Hz·x = 0, Gx·x ≠ 0)' : 'Z-type logical z (Hx·z = 0, Gz·z ≠ 0)';
  const chk = witnessParity(R, w);
  const final = R.final && R.final.d === w.weight;
  $('wInfo').innerHTML = `${final ? '<b>Minimum-weight witness</b>' : 'Best witness so far'}: weight <b>${w.weight}</b>, ${typ}, found by ${w.src}` +
    (chk === null ? '' : chk ? '; H·e = 0 re-checked in the page ✓' : '; <span class="mismatch">page re-check of H·e = 0 FAILED</span>') +
    `<br><span class="hint">qubits: ${w.support.join(' ')}</span>`;
  $('wDl').disabled = false;
  const bb = R.bb;
  if (!bb) return;
  const { l, m } = bb;
  const N = l * m, c = 12, gap = 18, lab = 14;
  const side = m <= 18;   // two grids side by side unless the grids are very wide
  const gw = m * c, gh = l * c;
  const W = side ? 2 * gw + gap : gw, H = side ? gh + lab : 2 * (gh + lab) + gap / 2;
  const sv = el('svg', { viewBox: `-2 -2 ${W + 4} ${H + 4}`, role: 'img', 'aria-label': 'Witness qubits on the two l by m torus grids' }, null);
  const on = new Set(w.support);
  for (let b = 0; b < 2; b++) {
    const ox = side ? b * (gw + gap) : 0, oy = side ? 0 : b * (gh + lab + gap / 2);
    el('text', { x: ox, y: oy + 10 }, sv).textContent = (b ? 'R' : 'L') + ' block (' + l + ' × ' + m + ')';
    for (let i = 0; i < l; i++) for (let j = 0; j < m; j++) {
      const q = b * N + i * m + j;
      const e = el('circle', { cx: ox + j * c + c / 2, cy: oy + lab + i * c + c / 2, r: c / 2 - 1.5, class: 'q' + (on.has(q) ? ' on' : '') }, sv);
      el('title', {}, e).textContent = 'qubit ' + q;
    }
  }
  box.appendChild(sv);
  const cap = document.createElement('p');
  cap.className = 'hint';
  cap.textContent = `Bivariate bicycle layout: qubit b·${N} + i·${m} + j sits at row i, column j of block L (b = 0) or R (b = 1); rows and columns wrap around (torus).`;
  box.appendChild(cap);
}
function witnessText() {
  const R = S.run, w = R.best;
  const v = new Array(R.n).fill(0);
  for (const q of w.support) v[q] = 1;
  return [
    '# DistQLDPC web demo witness',
    `# code: ${R.label}  n=${R.n}`,
    `# half: ${w.half} (${w.half === 'X' ? 'X-type logical x: Hz x = 0, not in rowspace(Hx)' : 'Z-type logical z: Hx z = 0, not in rowspace(Hz)'})`,
    `# weight: ${w.weight}  source: ${w.src}  final d: ${R.final ? R.final.d : 'n/a'}`,
    `# flags: ${R.flags}`,
    `# DistQLDPC ${S.version ? S.version.commit : ''}`,
    'support: ' + w.support.join(' '),
    v.join(' '),
    '',
  ].join('\n');
}

/* ---------- result panel ---------- */
function setStatus(text, cls) { const s = $('status'); s.textContent = text; s.className = 'status ' + cls; }
function refreshResult() {
  const R = S.run;
  if (!R) return;
  const lb = R.lb.length ? R.lb[R.lb.length - 1].v : null, ub = R.ub.length ? R.ub[R.ub.length - 1].v : null;
  $('rBounds').textContent = (lb === null ? '–' : lb) + ' / ' + (ub === null ? '–' : ub);
  $('rNK').textContent = R.n ? `n = ${R.n}, k = ${R.k !== null ? R.k : '?'}` : '–';
  $('rTime').textContent = fmtSec(runNow(R)) + (R.final ? ` (engine ${fmtSec(R.final.secs)})` : '');
  $('rMem').textContent = R.heap ? (R.heap / 1048576).toFixed(0) + ' MB heap' : '–';
  if (R.final && R.final.d >= 0) {
    $('dVal').textContent = R.final.d;
    if (R.expected !== null) {
      const ok = R.final.d === R.expected;
      $('rExp').innerHTML = `${R.expected} <span class="${ok ? 'match' : 'mismatch'}">${ok ? '✓ matches' : '✗ differs'}</span>`;
    }
  } else if (lb !== null || ub !== null) {
    $('dVal').textContent = lb === ub && lb !== null ? lb : `${lb === null ? '?' : lb}…${ub === null ? '?' : ub}`;
  }
}

/* ---------- events from the worker ---------- */
function onEvent(line) {
  const R = S.run;
  const t = (performance.now() - R.t0) / 1000;
  const a = line.split(' ');
  if ($('showEvents').checked || a[0] === 'NOTE') logAppend(['» ' + line], 'ev');
  switch (a[0]) {
    case 'LB': { const v = +a[1]; if (!R.lb.length || R.lb[R.lb.length - 1].v !== v) R.lb.push({ t, v }); break; }
    case 'UB': { const v = +a[1]; if (!R.ub.length || R.ub[R.ub.length - 1].v !== v) R.ub.push({ t, v }); break; }
    case 'TRY': if (!R.final) setStatus('running · testing weight ' + a[1], 'run'); break;
    case 'INFO': R.n = +a[2]; R.k = +a[8]; break;
    case 'ENGINE': R.engine = a[1]; $('rEng').textContent = a[1] === 'cc' ? 'connected cluster (CC)' : 'MaxSAT (MaxCDCL)'; break;
    case 'LOGICALS': if (a[1] === 'computed') logAppend([`» Gx, Gz computed from Hx, Hz: ${a[3]} logical rows each (${fmtSec(+a[6])})`], 'ev'); break;
    case 'PROBE':
      R.rows++;
      addRow([R.rows, a[1], a[2], a[3], a[4], a[4] === 'FOUND' || a[4] === 'OPT' ? a[5] : '', fmtInt(a[6]), fmtSec(+a[7])], 4);
      break;
    case 'LEVEL':
      R.rows++;
      addRow([R.rows, a[1], a[2], a[3], fmtInt(a[4]), fmtSec(+a[5])], 3);
      break;
    case 'WITNESS': {
      const w = { half: a[1], weight: +a[2], src: a[3], support: a.slice(4).map(Number) };
      if (!R.best || w.weight < R.best.weight) { R.best = w; showWitness(); }
      break;
    }
    case 'FINAL': {
      const d = +a[1];
      R.final = { d, status: a[2], lb: a[4], ub: a[6], secs: +a[7] };
      if (d >= 0) {
        if (!R.lb.length || R.lb[R.lb.length - 1].v !== d) R.lb.push({ t, v: d });
        if (!R.ub.length || R.ub[R.ub.length - 1].v !== d) R.ub.push({ t, v: d });
      }
      break;
    }
    default: break;
  }
  scheduleDraw();
}
let drawPending = false;
function scheduleDraw() {
  if (drawPending) return;
  drawPending = true;
  requestAnimationFrame(() => { drawPending = false; drawChart(); refreshResult(); });
}

/* ---------- run / stop ---------- */
function endRun(statusText, cls) {
  const R = S.run;
  if (!R || R.end !== null) return;
  R.end = (performance.now() - R.t0) / 1000;
  clearInterval(R.tick);
  clearTimeout(R.backstop);
  if (R.worker) { R.worker.terminate(); R.worker = null; }
  $('runBtn').disabled = false;
  $('stopBtn').disabled = true;
  setStatus(statusText, cls);
  showWitness();
  drawChart();
  refreshResult();
}
async function startRun() {
  if (S.run && S.run.end === null) return;
  const flags = buildFlags();
  let job, label, n, k = null, expected = null, bb = null, Hx = null, Hz = null, native = null;
  try {
    if (S.mode === 'bundled') {
      const stem = $('codeSel').value;
      setStatus('loading ' + stem + ' …', 'run');
      const c = await getCode(stem);
      job = { hx: sparseToText(c.Hx, c.n), hz: sparseToText(c.Hz, c.n), gx: sparseToText(c.Gx, c.n), gz: sparseToText(c.Gz, c.n), flags };
      label = stem; n = c.n; k = c.k; expected = c.d; bb = c.bb; Hx = c.Hx; Hz = c.Hz;
      const meta = S.index.find((x) => x.stem === stem);
      native = meta && meta.timing ? meta.timing[engineValue()] : null;
    } else {
      const hx = $('txHx').value, hz = $('txHz').value;
      const px = textToSparse(hx), pz = textToSparse(hz);
      if (!px.rows.length || !pz.rows.length) { setStatus('enter Hx and Hz first', 'bad'); return; }
      if (px.n !== pz.n) { setStatus(`Hx has ${px.n} columns, Hz has ${pz.n}`, 'bad'); return; }
      job = { hx, hz, gx: $('txGx').value, gz: $('txGz').value, flags };
      label = 'user matrices'; n = px.n; Hx = px.rows; Hz = pz.rows;
    }
  } catch (e) {
    setStatus(String(e.message || e), 'bad');
    return;
  }
  logClear();
  setTable(engineValue());
  const R = S.run = {
    t0: performance.now(), end: null, lb: [], ub: [], rows: 0, best: null, final: null, heap: 0,
    label, n, k, expected, bb, Hx, Hz, flags, engine: engineValue(), worker: null,
  };
  $('dVal').textContent = '…';
  $('rCode').textContent = label;
  $('rExp').textContent = expected !== null ? String(expected) : '–';
  $('rEng').textContent = R.engine === 'cc' ? 'connected cluster (CC)' : 'MaxSAT (MaxCDCL)';
  $('rNative').textContent = native !== null && native !== undefined ? fmtSec(native) + ' (1 core)' : '–';
  $('flagsUsed').textContent = flags;
  showWitness();
  setStatus('starting WebAssembly worker …', 'run');
  $('runBtn').disabled = true;
  $('stopBtn').disabled = false;
  logAppend(['$ distqldpc ' + flags + ' ' + label], 'ev');
  const w = new Worker('worker.js');
  R.worker = w;
  w.onmessage = (ev) => {
    const m = ev.data;
    if (S.run !== R) return;
    if (m.heap) R.heap = Math.max(R.heap, m.heap);
    if (m.t === 'ev') onEvent(m.line);
    else if (m.t === 'out') logAppend(m.lines, null);
    else if (m.t === 'err') logAppend(m.lines, 'err');
    else if (m.t === 'ready') setStatus('running', 'run');
    else if (m.t === 'done') {
      const f = R.final;
      if (f && f.d >= 0) endRun(`done · d = ${f.d} (proved optimal)`, 'ok');
      else if (f && f.status === 'TIMEOUT') endRun('time limit reached · bounds above are proven', 'warn');
      else endRun('finished without an answer' + (f ? ' (' + f.status + ')' : ''), 'bad');
    } else if (m.t === 'exit') endRun('stopped: input error (see log)', 'bad');
  };
  w.onerror = (e) => { if (S.run === R) { logAppend(['worker error: ' + e.message], 'err'); endRun('worker error', 'bad'); } };
  w.postMessage(job);
  R.tick = setInterval(() => { drawChart(); refreshResult(); }, 250);
  const lim = Math.max(1, parseInt($('timeLim').value, 10) || 120);
  R.backstop = setTimeout(() => endRun('time limit reached (worker terminated) · bounds above are proven', 'warn'), (lim + 15) * 1000);
}
function stopRun() {
  if (!S.run || S.run.end !== null) return;
  logAppend(['» stopped by the user (worker terminated)'], 'ev');
  endRun('stopped by the user · bounds above are proven', 'warn');
}

/* ---------- wiring ---------- */
async function init() {
  try {
    const r = await fetch('version.json');
    if (r.ok) S.version = await r.json();
  } catch (e) { /* local build without version.json */ }
  if (S.version) {
    $('ver').textContent = `commit ${S.version.commit}` + (S.version.date ? ` (${S.version.date})` : '') +
      (S.version.emcc ? `, emscripten ${S.version.emcc}` : '');
    const url = 'https://github.com/guluchen/DistQLDPC/tree/' + S.version.commit;
    $('srcLink').href = url;
    $('srcLink2').href = url;
  }
  await loadIndex();
  $('modeBundled').onclick = () => setMode('bundled');
  $('modeOwn').onclick = () => setMode('own');
  document.querySelectorAll('#left input').forEach((x) => x.addEventListener('change', refreshOptions));
  $('codeSel').onchange = () => { suggestLimit(); refreshHint(); };
  document.querySelectorAll('input[name=engine]').forEach((x) => x.addEventListener('change', suggestLimit));
  $('runBtn').onclick = startRun;
  $('stopBtn').onclick = stopRun;
  $('wDl').onclick = () => S.run && S.run.best && download(`${S.run.label.replace(/\W+/g, '_')}_witness_w${S.run.best.weight}.txt`, witnessText());
  for (const k of ['Hx', 'Hz', 'Gx', 'Gz']) {
    $('f' + k).onchange = async (ev) => { const f = ev.target.files[0]; if (f) $('tx' + k).value = await f.text(); };
  }
  $('loadExample').onclick = async () => {
    const c = await getCode('BB_72_12_6');
    $('txHx').value = sparseToText(c.Hx, c.n);
    $('txHz').value = sparseToText(c.Hz, c.n);
    $('txGx').value = '';
    $('txGz').value = '';
  };
  svg.addEventListener('mousemove', chartHover);
  svg.addEventListener('mouseleave', () => { $('tip').hidden = true; drawChart(); });
  window.addEventListener('resize', drawChart);
  // deep link: #code=STEM&engine=cc|maxsat&limit=S&run=1
  const h = new URLSearchParams(location.hash.slice(1));
  if (h.get('code') && S.index.find((c) => c.stem === h.get('code'))) $('codeSel').value = h.get('code');
  if (h.get('engine')) { const r = document.querySelector(`input[name=engine][value="${h.get('engine')}"]`); if (r) r.checked = true; }
  suggestLimit();
  if (h.get('limit')) $('timeLim').value = h.get('limit');
  refreshOptions();
  drawChart();
  if (h.get('run') === '1') startRun();
}
init();
