import pathlib, subprocess, json, hashlib
root = pathlib.Path('GH16-PGO')
e = json.loads(pathlib.Path('GH16-windows-preparation-04/environment.json').read_text())
out = {}
h = lambda b: hashlib.sha256(b).hexdigest()
old = 'ad06d1ad389e9aa87ff3331b8f06e6b61b0177c6'
norm = lambda b: b.replace(b'\r\n', b'\n')
for rel, recorded in e['source_hashes'].items():
    r = rel.replace('\\', '/')
    prior = subprocess.check_output(['git', 'show', old + ':' + r], cwd=root)
    current = (root / rel).read_bytes()
    out[r] = {'executed_hash': recorded, 'previous_commit_byte_hash': h(prior),
              'matches_executed': recorded in (h(prior), h(current)),
              'LF_content_identical': norm(prior) == norm(current),
              'current_byte_hash': h(current), 'LF_content_sha256': h(norm(current))}
pathlib.Path('GH16-hosted/source-reconciliation.json').write_text(json.dumps(out, indent=2), encoding='utf8')
print(json.dumps(out, indent=2))
assert all(x['matches_executed'] and x['LF_content_identical'] for x in out.values())
