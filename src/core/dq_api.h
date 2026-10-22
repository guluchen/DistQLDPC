/*
 * DistQLDPC — in-process library entry point (web demo, WebAssembly build).
 *
 * Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * dq_solve runs the same code as the bin/distqldpc CLI (same flags, same engines, same stdout text), but in the
 * calling process: no fork, no pipe, no signals. Every bound line of the CLI's pipe protocol and a few structured
 * events are delivered to a callback, one line per call (no trailing newline):
 *
 *   TRY <w>                          the search tests weight w            (CLI: c trying d: w)
 *   LB <v> / UB <v>                  proven lower / best upper bound       (CLI: c d_lb / c d_ub)
 *   RESULT <d> OPTIMAL | RESULT -1 UNKNOWN | RESULT -1 TRAP   final engine verdict (TRAP withdraws earlier bounds)
 *   INFO n <n> Hx <rows> Hz <rows> Gx <rows> Gz <rows>        after the input is read
 *   LOGICALS computed|given Gx <rows> Gz <rows> <seconds>    Gx / Gz given, or computed from Hx / Hz
 *   ENGINE maxsat|cc                 engine actually used (after -engine=auto)
 *   PROBE <half> <cap> <feasibility|optimize> <FOUND|OPT|NONE|UNKNOWN|INFEASIBLE> <value> <conflicts> <seconds>
 *                                    one MaxSAT oracle call of the interleaved CSS-split search
 *   LEVEL <half> <w> <EMPTY|FOUND|ABORTED|INCONSISTENT> <nodes> <seconds>   one finished CC weight level
 *   WITNESS <half> <weight> <source> <q0> <q1> ...   a verified logical of that half (H e = 0, detected by G and
 *                                    not in the row space of the same-type stabilizers); qubit indices 0..n-1;
 *                                    source: maxsat, ub-pre, cc-level, cc-ub-search, cc-basis
 *   NOTE <text>                      informational
 *   FINAL <d|-1> <OPTIMAL|TIMEOUT|CANCELLED|TRAP|UNKNOWN> lb <v|-> ub <v|-> <seconds>
 *
 * The CLI's log (c ... lines; with -v the full search log) is written to stdout as usual (in the WebAssembly
 * build: Module.print). Fatal input errors print "error: ..." on stderr and exit (in the browser the Web Worker
 * that runs the module is discarded, see web/worker.js).
 *
 * flags: the CLI options, whitespace separated (e.g. "-engine=cc -cpu-lim=60"). -cpu-lim=N is a wall-clock deadline
 * polled inside both engines (the run stops with the bounds proven so far, status TIMEOUT). dq_cancel() requests
 * the same stop from another thread (native callers); in the browser, Stop terminates the worker instead.
 * Matrices: the CLI's text format (one row of 0/1 entries per line, '#' comments). gx / gz NULL or empty: both are
 * computed from hx / hz (the GF(2) quotient bases of scripts/compute_logicals.py). One dq_solve at a time.
 */
#ifndef DISTQLDPC_DQ_API_H
#define DISTQLDPC_DQ_API_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*dq_event_fn)(const char* line, void* user);

/* Returns d >= 0 when the distance was determined, -1 otherwise (timeout, cancel, no answer, report flags). */
int dq_solve(const char* hx, const char* hz, const char* gx_or_null, const char* gz_or_null, const char* flags,
             dq_event_fn cb, void* user);

/* Requests a stop of the running dq_solve (thread-safe flag; polled by both engines). */
void dq_cancel(void);

/* Gx (ker Hx / rs Hz) and Gz (ker Hz / rs Hx) as malloc'ed matrix text (free with free()); returns k (the number
 * of rows of each). Input errors are fatal as in dq_solve. */
int dq_compute_logicals(const char* hx, const char* hz, char** gx_out, char** gz_out);

/* Git commit the library was built from ("unknown" if not set at build time). */
const char* dq_version(void);

#ifdef __cplusplus
}
#endif

#endif
