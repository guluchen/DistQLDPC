"""Read-only original Cygwin subset verifier; runs only inside assigned Job."""
import argparse
import hashlib
import json
from pathlib import Path

def main():
    ap=argparse.ArgumentParser()
    for name in ("runtime","manifest","out"):ap.add_argument("--"+name,type=Path,required=True)
    args=ap.parse_args();root=args.runtime.resolve()
    expected=json.loads(args.manifest.read_text());actual={}
    for relative,digest in expected.items():
        p=root/relative
        if p.is_symlink() or root not in p.resolve().parents:
            raise ValueError("Original runtime alias escapes/unverified symlink: "+relative)
        actual[relative]=hashlib.sha256(p.read_bytes()).hexdigest()
        if actual[relative]!=digest:raise ValueError("Original runtime byte mismatch: "+relative)
    args.out.write_text(json.dumps({"status":"PASS","verified_original_files":len(actual),
                                   "manifest_sha256":hashlib.sha256(args.manifest.read_bytes()).hexdigest(),
                                   "files":actual},indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"PASS","verified_original_files":len(actual)}))
if __name__=="__main__":main()
