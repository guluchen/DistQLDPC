"""Regenerate Clight from the production CC kernel and check its VST proofs."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory


# Dependency order. Each project module is an explicit coqchk target.
MODULES = (
    "VerifDetected", "PackedDetector", "VerifPackedDetector",
    "LeafClosure", "LeafMatrix", "DetectorMatrix", "SiblingExclusion",
    "VerifClosesCount", "VerifDfsLeaf", "VerifClosesBody",
    "MinimumPrefix", "LevelSearch", "CSSLevelDistance",
    "ClosureEncoding", "ClosureWord", "ClosureMatrix", "MinimumOverlap", "ChargeBound",
    "ToggleModel", "SyndromeHash", "VerifToggleBody",
    "DetectorRank", "SparseFlipBits", "SparseSyndrome", "SparseRollback",
    "VerifFlipBody",
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    proof_dir = Path(__file__).resolve().parent
    source_dir = proof_dir.parents[2] / "src" / "cc"
    compiler = os.environ.get("CLIGHTGEN", "clightgen")
    flags = []
    if "VST_ROOT" in os.environ:
        vst = Path(os.environ["VST_ROOT"]).resolve()
        for package in ("msl", "sepcomp", "veric", "floyd", "zlist"):
            flags.extend(["-Q", str(vst / package), "VST." + package])
        flags.extend(["-R", str(vst / "compcert"), "compcert"])

    with TemporaryDirectory(prefix="distqldpc-level-") as temp:
        build = Path(temp)
        ast = build / "level_ast.v"
        proofs = [build / (name + ".v") for name in MODULES]
        for proof in proofs:
            shutil.copyfile(proof_dir / proof.name, proof)
        subprocess.run([compiler, "-normalize", "-canonical-idents", "-o",
                        str(ast), "cc_level.c"], cwd=source_dir, check=True)
        for module in [ast, *proofs]:
            subprocess.run(["coqc", *flags, module.name], cwd=build, check=True)
        check_targets = [arg for name in ("level_ast", *MODULES)
                         for arg in ("-norec", name)]
        subprocess.run(["coqchk", "-silent", *flags, *check_targets],
                       cwd=build, check=True)
        inputs = [source_dir / "cc_level.c", source_dir / "cc_level.h", ast, *proofs]
        print(json.dumps({"checked_body": "detected",
                          "checked_paths": ["closes count mismatch", "closes full body",
                                            "dfs terminal depth without polling",
                                            "toggle full body", "flip full body"],
                          "modules": list(MODULES), "sha256": {
            path.name: digest(path) for path in inputs}}, indent=2))


if __name__ == "__main__":
    main()
