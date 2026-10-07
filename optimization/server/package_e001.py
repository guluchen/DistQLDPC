#!/usr/bin/env python3
"""Materialize the already-tested E001 snapshots as an offline Linux run package."""
import argparse
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CANDIDATE = '9d68f459019e9c5a20c5c513cf89aaf4a2cd2854'
QDIST = '7c4774fffc49856f48a22ae5f9063d00b2661aaa'


def git(repo, *args):
    # Windows Git archive applies core.autocrlf; Linux packages need blob bytes.
    return subprocess.check_output(['git', '-c', 'core.autocrlf=false',
        '-c', 'core.eol=lf', '-C', str(repo), *args])


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--qdistsat', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True, help='New package directory')
    a = ap.parse_args()
    repo = Path(__file__).resolve().parents[2]
    out = a.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    identities = {}
    for name, source, revision in [('baseline', repo, BASE),
                                   ('candidate', repo, CANDIDATE),
                                   ('qdistsat', a.qdistsat.resolve(), QDIST)]:
        identities[name] = git(source, 'rev-parse', revision).decode().strip()
        archive = git(source, 'archive', '--format=tar', identities[name])
        # Write only regular Git archive entries; preserve executable permissions.
        target = out / name
        target.mkdir()
        with tarfile.open(fileobj=io.BytesIO(archive)) as tf:
            for member in tf.getmembers():
                path = (target / member.name).resolve()
                if not path.is_relative_to(target):
                    raise ValueError('Unsafe archive path: ' + member.name)
                if member.isdir():
                    path.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(tf.extractfile(member).read())
                    path.chmod(member.mode)
                else:
                    raise ValueError('Unsupported archive entry: ' + member.name)
    files = {str(p.relative_to(out)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
             for p in sorted(out.rglob('*')) if p.is_file()}
    (out / 'manifest.json').write_text(json.dumps({'experiment': 'E001',
        'revisions': identities, 'files': files}, indent=2), encoding='utf-8')
    archive_path = out.with_suffix('.tar.gz')
    if archive_path.exists():
        raise FileExistsError(archive_path)
    with tarfile.open(archive_path, 'w:gz') as tf:
        tf.add(out, arcname=out.name)
    print(json.dumps({'package': str(archive_path), 'files': len(files),
        'sha256': hashlib.sha256(archive_path.read_bytes()).hexdigest(),
        'revisions': identities}, indent=2))


if __name__ == '__main__':
    main()
