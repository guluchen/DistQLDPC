#!/usr/bin/env python3
"""GH-206: the Tier 5 auto runs used -cc-probe-growth=30 (binary 14ec146, re-probes at 30x the last probe level). The searches
are deterministic and a probe never changes the current search's state, so when no re-probe switched the configuration, the
run with one probe per half (-cc-probe-growth=0, the final default) does exactly the same level searches minus the re-probe
levels. This script subtracts, from every lb / result event time, the time of the re-probes (2nd and later probe of a half)
that happened before it, and flags runs where a re-probe switched (not derivable).
usage: derive_single_probe.py LOG... (queue logs: '<elapsed>\\t<line>')"""
import re, sys, json
for path in sys.argv[1:]:
    probes = []; events = []; result = None; first = {}
    for line in open(path):
        if line.startswith('#'): continue
        t, _, rest = line.partition('\t')
        try: e = float(t)
        except ValueError: continue
        m = re.match(r'c cc-probe: (\w) level (\d+) (\w) (\w+) nodes \d+ time ([\d.]+)s (\w) ([\d.]+)s -> (\w)', rest)
        if m:
            h = m.group(1); sw = m.group(8) != m.group(6)
            probes.append(dict(t=e, half=h, level=int(m.group(2)), dur=float(m.group(5)), re=h in first, switched=sw))
            first.setdefault(h, True)
        m = re.match(r'c d_lb: (\d+)\s*$', rest)
        if m: events.append((e, int(m.group(1))))
        if rest.startswith('o '): result = (e, int(rest.split()[1]))
    bad = [p for p in probes if p['re'] and p['switched']]
    def adj(t): return t - sum(p['dur'] for p in probes if p['re'] and p['t'] <= t)
    out = dict(log=path.split('/')[-1], reprobes=sum(p['re'] for p in probes), reprobe_s=round(sum(p['dur'] for p in probes if p['re']), 1),
               reprobe_switched=len(bad), lb_events_single=[(round(adj(t)), v) for t, v in events if v >= 18],
               result_single=(round(adj(result[0]), 1), result[1]) if result else None,
               first_probes=[(p['half'], p['level'], 'switch' if p['switched'] else 'stay') for p in probes if not p['re']])
    print(json.dumps(out))
