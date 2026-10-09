#!/usr/bin/env python3
"""Export the pinned E001 experiment as an offline, checksummed Linux package."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile

BASELINE = "24572d6d09cce9a4a5faa58300a89e0feba9da6a"
CANDIDATE = "9d68f459019e9c5a20c5c513cf89aaf4a2cd2854"
IMPLEMENTATION = "50623f9710969288d3a9d1c6325f3a72c35ff6d5"
QDIST = "7c4774fffc49856f48a22ae5f9063d00b2661aaa"
CASES = ("LP_34_20_2", "LP_136_32_4", "BB_90_8_10", "GB_144_12_8",
         "BB_108_8_10", "LP_238_44_6", "LP_340_56_8")


def git(repo, *args):
    return subprocess.check_output([
        "git", "-c", "maintenance.auto=false", "-c", "gc.auto=0",
        "-c", "core.autocrlf=false", "-c", "core.eol=lf",
        "-C", str(repo), *args,
    ])


def export(repo, ref, paths, destination):
    # Export committed bytes, preserving LF and executable modes on Linux.
    archive = git(repo, "archive", "--format=tar", ref, *paths)
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        for member in source:
            relative = PurePosixPath(member.name)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError("Unsafe archive member: " + member.name)
            target = destination.joinpath(*relative.parts)
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.extractfile(member).read())
                target.chmod(member.mode)
            else:
                raise ValueError("Unexpected archive member: " + member.name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qdistsat-repo", type=Path, required=True,
                        help="Local ordinary or bare Git repo containing the pinned commit")
    parser.add_argument("--output", type=Path, required=True,
                        help="New directory; package folder and tar.gz will be written here")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    qdist = args.qdistsat_repo.resolve()
    for repository, ref in ((repo, BASELINE), (repo, CANDIDATE), (qdist, QDIST)):
        assert git(repository, "rev-parse", ref + "^{commit}").decode().strip() == ref
    assert not git(repo, "diff", IMPLEMENTATION, CANDIDATE, "--", "src", "Makefile")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    package = output / "E001-run-package"
    package.mkdir()
    matrices = [f"data/matrices/{case}_{suffix}.txt"
                for case in CASES for suffix in ("Hx", "Hz", "Gx", "Gz")]
    common = ["src", "Makefile", "LICENSE", "NOTICE", "MODIFICATIONS.md",
              "README.md", "AGENTS.md", "docs/OPTIMIZATION_LOOP_POLICY.md",
              "docs/QDISTSAT_CROSS_REPO_CI.md", "scripts/smoke_test.sh", *matrices]
    export(repo, BASELINE, common, package / "baseline")
    export(repo, CANDIDATE, common + [
        "optimization/server/run.py", "optimization/server/README.md",
        "optimization/tests", "optimization/experiments/E001/PROPOSAL.md",
        "optimization/experiments/E001/implementation.patch",
        "optimization/experiments/E001/input-identities.json",
    ], package / "candidate")
    # Read only the required blobs. This also works with a partial clone without
    # asking git archive to materialize unrelated QDistSAT data.
    qpaths = ["AGENTS.md", "LICENSE", "NOTICE", "README.md", "data/README.md",
              "benchmarks/compare_distqldpc_binaries.py"]
    for family, stem in (("LP", "LP_136_32_4"), ("BB", "BB_108_8_10")):
        qpaths.extend(f"data/{family}/{stem}_{s}.txt" for s in ("Hx", "Hz", "Gx", "Gz"))
    for relative in qpaths:
        target = package / "qdistsat" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(git(qdist, "show", QDIST + ":" + relative))
    identities = json.loads((package / "candidate/optimization/experiments/E001/input-identities.json").read_text())
    for relative, expected in identities.items():
        for version in ("baseline", "candidate"):
            assert hashlib.sha256((package / version / relative).read_bytes()).hexdigest() == expected, relative
    manifest = {
        "experiment": "E001", "baseline": BASELINE, "candidate": CANDIDATE,
        "candidate_implementation": IMPLEMENTATION, "qdistsat": QDIST,
        "scope": "Tier 0, Tier 1, conditional Tier 2; no Tier 3",
        "files": {p.relative_to(package).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in sorted(package.rglob("*")) if p.is_file()},
    }
    (package / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    archive = output / "E001-run-package.tar.gz"
    with tarfile.open(archive, "w:gz") as bundle:
        bundle.add(package, arcname=package.name)
    checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / "SHA256SUMS").write_text(checksum + "  " + archive.name + "\n", encoding="utf-8")
    print(json.dumps({"archive": str(archive), "sha256": checksum,
                      "manifest_files": len(manifest["files"]), "input_files_verified": len(identities) * 2}, indent=2))


if __name__ == "__main__":
    main()
