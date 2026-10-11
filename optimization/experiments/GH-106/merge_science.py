"""Merge chunked GH-106 science.json files (raw/tier0-science/chunk*/science.json) into one science.json."""
import json, sys, glob, os
out = sys.argv[1]; files = sorted(glob.glob(os.path.join(out, 'chunk*', 'science.json')))
res = []; metas = []
for f in files:
    d = json.load(open(f)); res += d['results']; metas.append(d['meta'])
res.sort(key=lambda r: (r['stem'], r['mode']))
meta = dict(metas[0]); meta['chunks'] = [{k: m[k] for k in ('started', 'finished')} for m in metas]
meta['all_ok'] = all(r['ok'] for r in res)
meta['counts'] = {'cases': len(res),
                  'both_done': sum(r['base']['status'] == 'done' and r['cand']['status'] == 'done' for r in res),
                  'only_cand_done': sum(r['base']['status'] != 'done' and r['cand']['status'] == 'done' for r in res),
                  'only_base_done': sum(r['base']['status'] == 'done' and r['cand']['status'] != 'done' for r in res),
                  'problems': sum(bool(r['problems']) for r in res),
                  'memout_base': sum(r['base']['status'] == 'MEMOUT' for r in res),
                  'memout_cand': sum(r['cand']['status'] == 'MEMOUT' for r in res)}
json.dump({'meta': meta, 'results': res}, open(os.path.join(out, 'science.json'), 'w'), indent=1)
print(json.dumps(meta['counts']), 'ALL_OK' if meta['all_ok'] else 'STOP')
