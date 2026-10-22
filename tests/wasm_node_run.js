#!/usr/bin/env node
/*
 * DistQLDPC web demo — run the WebAssembly module (web/dq.js + web/dq.wasm) under Node.js, for checks without a
 * browser. Usage: node tests/wasm_node_run.js <prefix> [--compute-g] [flags...]
 * Prints the module's stdout (the CLI's text), every event as "E <line>", and "E WALL <seconds>" at the end.
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
const fs = require('fs');
const path = require('path');
const createDQ = require(path.join(__dirname, '..', 'web', 'dq.js'));
const args = process.argv.slice(2);
const prefix = args.shift();
let computeG = false;
const flags = args.filter(a => (a === '--compute-g' ? ((computeG = true), false) : true)).join(' ');
const rd = s => fs.readFileSync(prefix + s, 'utf8');
const t0 = Date.now();
createDQ({ print: l => console.log(l), printErr: l => console.error(l) }).then(M => {
  M.onDqEvent = line => console.log('E ' + line);
  const put = s => { const n = M.lengthBytesUTF8(s) + 1; const p = M._malloc(n); M.stringToUTF8(s, p, n); return p; };
  const ptrs = [rd('_Hx.txt'), rd('_Hz.txt'), computeG ? '' : rd('_Gx.txt'), computeG ? '' : rd('_Gz.txt'), flags].map(put);
  let d;
  try {
    d = M._dq_solve_js(...ptrs);
  } catch (e) {
    console.log('E EXCEPTION ' + (e && e.name) + ' ' + (e && e.status !== undefined ? 'status ' + e.status : String(e)));
  }
  console.log('E RETURN ' + d + ' heapMB ' + (M.HEAPU8.length / 1048576).toFixed(0));
  console.log('E WALL ' + ((Date.now() - t0) / 1000).toFixed(3));
});
