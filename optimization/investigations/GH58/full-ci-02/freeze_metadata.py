"""Metadata-only source manifest; no compiler/solver/module imports."""
from pathlib import Path
import argparse,hashlib,json
def main():
    ap=argparse.ArgumentParser();ap.add_argument('support',type=Path);a=ap.parse_args();root=a.support.resolve()
    rows={}
    for p in sorted(root.rglob('*')):
        assert not p.is_symlink() and p.name!='__pycache__' and p.suffix!='.pyc'
        if p.is_file() and p.name!='manifest.json':
            rows[str(p.relative_to(root)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
    assert {'full.py','ci.py','corpus.py','science.py','guard.py','PRERECORD.md','CI-ADAPTER-PRERECORD.md'}<=set(rows)
    target=root/'manifest.json';assert not target.exists(),'Fresh manifest only; preserve old freezes'
    target.write_text(json.dumps(rows,indent=2)+'\n',encoding='utf8')
    print(json.dumps(dict(support=str(root),files=len(rows),manifest_sha=hashlib.sha256(target.read_bytes()).hexdigest(),source_only=True)))
if __name__=='__main__':main()
