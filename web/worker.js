/*
 * DistQLDPC web demo — Web Worker that runs one distance computation in the WebAssembly module (dq.js / dq.wasm).
 * One worker per run: the page creates a fresh worker for every run and terminates it to stop (so a stop never has
 * to be cooperative, and every run starts from the module's initial state).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Messages to the page: {t:'ready'} | {t:'ev', line, heap} (a dq_api.h event) | {t:'out', lines} / {t:'err', lines}
 * (the CLI's stdout / stderr, batched) | {t:'done', d, heap} | {t:'exit', status, msg} (fatal input error).
 */
/* global createDQ */
importScripts('dq.js');

let outBuf = [], errBuf = [], lastFlush = 0;

function flush() {
  if (outBuf.length) { postMessage({ t: 'out', lines: outBuf }); outBuf = []; }
  if (errBuf.length) { postMessage({ t: 'err', lines: errBuf }); errBuf = []; }
  lastFlush = Date.now();
}

function maybeFlush() {
  if (outBuf.length + errBuf.length >= 200 || Date.now() - lastFlush > 100) flush();
}

onmessage = async (msg) => {
  const job = msg.data;
  let M;
  try {
    M = await createDQ({
      print: (l) => { outBuf.push(l); maybeFlush(); },
      printErr: (l) => { errBuf.push(l); maybeFlush(); },
    });
  } catch (e) {
    postMessage({ t: 'exit', status: -1, msg: 'could not load the WebAssembly module: ' + e });
    return;
  }
  const heap = () => M.HEAPU8.length;
  M.onDqEvent = (line) => { flush(); postMessage({ t: 'ev', line, heap: heap() }); };
  const put = (s) => {
    const n = M.lengthBytesUTF8(s) + 1;
    const p = M._malloc(n);
    M.stringToUTF8(s, p, n);
    return p;
  };
  postMessage({ t: 'ready', version: M.UTF8ToString(M._dq_version()) });
  const args = [job.hx, job.hz, job.gx || '', job.gz || '', job.flags].map(put);
  try {
    const d = M._dq_solve_js(...args);
    flush();
    postMessage({ t: 'done', d, heap: heap() });
  } catch (e) {
    flush();
    postMessage({ t: 'exit', status: e && e.status !== undefined ? e.status : -1, msg: String(e && e.message || e), heap: heap() });
  }
};
