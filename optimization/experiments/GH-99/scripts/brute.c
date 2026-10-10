/* GH-60 exhaustive oracle: minimum soft cost of a small WCNF (n <= 24). Prints "opt C" or "unsat". */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char** argv) {
  FILE* f = fopen(argv[1], "r"); if (!f) return 2;
  int n = 0, m = 0; long top = 0; char line[4096];
  int lits[20000]; int start[2000], len[2000]; long w[2000]; int nl = 0, nc = 0;
  while (fgets(line, sizeof line, f)) {
    if (line[0] == 'c') continue;
    if (line[0] == 'p') { sscanf(line, "p wcnf %d %d %ld", &n, &m, &top); continue; }
    char* p = line; long wt = strtol(p, &p, 10); int k = 0; start[nc] = nl;
    for (;;) { int x = (int)strtol(p, &p, 10); if (x == 0) break; lits[nl++] = x; k++; }
    len[nc] = k; w[nc] = wt; nc++;
  }
  long best = -1;
  for (unsigned long a = 0; a < (1UL << n); a++) {
    long cost = 0; int ok = 1;
    for (int c = 0; c < nc && ok; c++) {
      int sat = 0;
      for (int i = 0; i < len[c]; i++) { int x = lits[start[c] + i]; int v = abs(x) - 1; int val = (a >> v) & 1; if ((x > 0) == val) { sat = 1; break; } }
      if (!sat) { if (w[c] >= top) ok = 0; else cost += w[c]; }
    }
    if (ok && (best < 0 || cost < best)) best = cost;
  }
  if (best < 0) printf("unsat\n"); else printf("opt %ld\n", best);
  return 0;
}
