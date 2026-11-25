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
    "HashLookup", "HashProbe", "VerifLookup",
    "IndexPacking", "OrbitSeed", "ParityPrune", "VerifClosedPrefix",
    "RedundantState", "OrbitLevel", "VerifOneLeft", "VerifSeedIndex",
    "LowestWord", "WordScan", "VerifLowestBit",
    "LeafShortcut", "RowTally", "NativeLeafChoice",
    "PrunedLevel", "PhysicalPrunes", "LocalCharge", "TiebreakTarget",
    "SiblingCounters", "LeafAPI", "PCMLeafAPI", "VerifPolicyParity",
    "TableFlow", "TableCoverage", "TableMembers", "BuiltLookup",
    "BucketPipeline", "VerifTableBuild", "BuiltPCM",
    "ClightSelect", "TableTotal", "ErasureProjection", "RowGather",
    "VerifPhysicalStep", "VerifPolicyStep", "PCMSearchStep",
    "VerifSiblingRollback", "VerifLastPair", "VerifLastPairClosed",
    "ClightNested", "OrbitPreferred",
    "ActiveChildren", "VerifGather", "EpochFreshness", "VerifEpoch",
    "PreferredTraversal", "VerifRowTally", "VerifMarkRow", "RowMarkSemantics",
    "VerifPackCallback",
    "ErasureBacksub",
    "ErasureElimination",
    "CSRWordTraversal",
    "ColumnParityPCM",
    "CertifiedSchedule",
    "DualDistance",
    "IndexRowBridge",
    "EvenOverlapLimit",
    "CSSSearchSchedule",
    "ErasureBasisMap",
    "VerifPollAbort",
    "SearchFuel",
    "FlipRoundtrip",
    "VerifOrbitBlock",
    "VerifChildVisit",
    "SiblingSearchCoverage",
    "VerifVisitRestoration",
    "NativePackingScan",
    "OverlapRowState",
    "OverlapRowSpecs",
    "OverlapColumnState",
    "VerifOverlapRows",
    "VerifOverlapDispatch",
    "OverlapView",
    "OverlapRollback",
    "OverlapChildState",
    "VerifOverlapOwner",
    "NativeBoundAlgebra",
    "NativeBoundSafety",
    "VerifSeedOverlap",
    "VerifOverlapUpdate",
    "VerifDriverBounds",
    "OverlapSharedBlocks",
    "ChildColumn", "EnabledCall", "EnabledLoopFacts", "VerifEnabledVisit",
    "VerifEnabledSiblings", "VerifEnabledUndo", "NativeHalfExists",
    "ValidatedHalfStart", "OverlapTargetProgress", "EffectiveRowTarget",
    "VerifOverlapGuard",
    "PCMOverlapHits", "SeedExemptionState", "SeedColumnModel", "VerifSeedMove",
    "VerifSeedOwner", "SeedPolicyView", "VerifSeedVisit", "SeedBlockModel",
    "SeedBlockView", "VerifRememberColumn", "VerifRememberBlock", "ExemptionRollback",
    "SeedTransferTrace", "SeedColumnRestore", "SeedResume", "SeedSharedView",
    "SeedStorageTransition", "SeedOrbitStorage", "SeedLoopModel", "VerifPolicySeeds",
    "EmptySeedColumns", "EmptyOrbitBlocks", "VerifSeedBranch", "VerifRootCall",
    "VerifRootAdmission", "DynamicOverlapCallback", "SeedCallFrame", "RootOwnerMemory",
    "SeedFramedCallback",
    "ActualOrbitCommit", "RootSearchPhases", "StableSeedPreference", "UniversalRootSearch",
    "UniformSeedControl", "LiveRootPolicy", "OrbitHeapLoan", "PCMSeedSafety",
    "SeedTableSafety", "BlockTableSafety", "RootTableInvariant", "SeedExecution",
    "PreparedSeed", "RootDriver", "ConcreteSeedSafety", "FunctionPointerGuard",
    "PreparedPolicyOptions", "PreparedSeedDispatch", "PreparedPrimitives", "PreparedRootStages",
    "PreparedRootLoop", "PreparedOverlapCalls", "PreparedRootOrbit",
    "PreparedOwnerLoan", "PreparedOrbitNoNotify", "PreparedExemptionFrame",
    "PreparedDFSTerminal", "PreparedDFSClosed", "PreparedDFSAbort",
    "PreparedFlip", "PreparedDFSParity", "PreparedOrbitLoan",
    "PreparedRecursiveCall", "PreparedRootAdmission", "PreparedLevelStorage",
    "PreparedPhysicalVisit", "PreparedDFSOneLeft", "PreparedExhaustionEvidence",
    "PreparedMinimumExclusion", "PreparedSeedResult", "PreparedSourceDriver",
    "PreparedTablesDriver", "OverlapTableAdmission", "PreparedDeadline",
    "NativeFlipPayload", "NativeRootFlip", "PreparedPhysicalPCM",
    "FramedRootFlip", "PreparedDepthSpec", "PreparedBudgetContract", "PreparedChildCall",
    "NativeDepthFlip", "PhysicalColumnBounds", "PhysicalPrefixInvariant",
    "PreparedPCMDepth", "PreparedChildPlain", "PreparedChildMode", "PreparedSiblingScan",
    "PreparedSiblingRestore", "PreparedDriverDepth", "PreparedPairDispatch",
    "PreparedOverlapDepth", "PreparedVisitAccounting", "PreparedSampling",
    "PreparedCandidateSlice", "PreparedTargetCoverage", "PreparedChoiceCall",
    "PreparedCandidateArena", "PreparedArenaContext", "PreparedArenaRoot", "PreparedArenaScan",
    "PreparedOwnerFields", "PreparedTerminalPoll", "PreparedMatrixResponse", "PreparedMatrixPath",
    "PreparedWitnessWeight", "PreparedCSSTerminal",
    "PreparedPlainCoverage", "PreparedRowCoverage", "PreparedResidualIndex", "PreparedScanFromPCM",
    "PreparedBudgetArena", "PreparedTerminalTrace", "PreparedNativeCallees", "PreparedPairStorage",
    "PreparedAnswerFrame", "PreparedOpenPair", "PreparedPrefixKernel", "PreparedBudgetDriver",
    "PreparedCallerLocals", "PreparedClosedPairMemory", "PreparedClosedPair",
    "PreparedLookupMatrix", "PreparedPairBracket", "PreparedClosedBracket",
    "PreparedWitnessRegister", "PreparedPairTrace", "PreparedPairCSS",
    "PreparedPhysicalPair", "PreparedShortCSS", "PreparedPairLedger",
    "PreparedPairEvent", "PreparedLeafWorkspace", "PreparedBothLeaves",
    "PreparedLeafVisit", "PreparedInstalledScan", "PreparedInstalledUndo",
    "PreparedLeafLoopBridge", "PreparedPCMLeafVisit", "PreparedLeafMinimum",
    "PreparedLeafAtPath", "PreparedReusableBook", "PreparedInitialLookup",
    "PreparedSelectedBlocks", "PreparedChildPrefix",
    "PreparedFastCoverage", "PreparedObservedWitness", "PreparedLeafReport",
    "PreparedInteriorReport", "PreparedDescentFuel", "PreparedPCMInterior", "PreparedPreferredOverlap", "PreparedPreferredSeed",
    "PreparedRootWitness", "PreparedWeightCases", "PreparedCutReports", "PreparedFinalLookup",
    "PreparedZeroPCM", "PreparedReadWitness", "PreparedProtectedCounts", "PreparedSeedSlack",
    "PreparedCertifiedBounds", "PreparedCSSRootPost",
    "PreparedPackingVerdict", "PreparedOrbitCredit", "PreparedReachedOrbit",
    "PreparedZeroLimitRows", "PreparedSeedAdmission", "PreparedVerifiedSeedRoot",
    "PreparedReturnTrace",
    "PreparedVerdictExit", "PreparedInteriorExit", "PreparedSampleOwnerReturn",
    "PreparedLeafReturnContract", "PreparedFastRecursive",
    "PreparedInitializeScan", "PreparedSelectedReturn", "PreparedChooseReturn",
    "PreparedInteriorEntry", "PreparedEmptyLoops", "PreparedDFSRejected",
    "PreparedPrunedPCM",
    "PreparedInteriorGuards",
    "PreparedChosenPhysicalRow", "PreparedNoLogical", "PreparedWritableChoice", "PreparedCounterJoin",
    "PreparedRankedChildren", "PreparedPCMFastSearch", "PreparedReusableSample", "PreparedBoundedEntry", "PreparedGatherCandidates", "PreparedConstructedRow", "PreparedRowAppend",
    "PreparedIndexWords", "PreparedIndexCandidates", "PreparedIndexGather",
    "PreparedIndexCuts", "PreparedIndexAdmission",
    "PreparedIndexWordStep", "PreparedIndexAdvance",
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
        translations = [
            ("level_ast", proof_dir / "reference" / "cc_level.c"),
            ("flag_level_ast", source_dir / "cc_level.c"),
            ("pack_ast", proof_dir / "pack_row_ast.c"),
            ("candidate_row_ast", proof_dir / "candidate_row_ast.c"),
            ("row_builder_ast", proof_dir / "row_builder_ast.c"),
            ("overlap_ast", proof_dir / "overlap_ast.c"),
            ("driver_ast", proof_dir / "driver_bounds_ast.c"),
            ("owner_ast", proof_dir / "overlap_policy_ast.c"),
            ("seed_ast", proof_dir / "seed_policy_ast.c"),
        ]
        generated = []
        for name, source in translations:
            target = build / (name + ".v")
            subprocess.run([compiler, "-normalize", "-canonical-idents", "-o", str(target),
                            source.name], cwd=source.parent, check=True)
            generated.append(target)
        proofs = [build / (name + ".v") for name in MODULES]
        for proof in proofs:
            shutil.copyfile(proof_dir / proof.name, proof)
        for module in [*generated, *proofs]:
            subprocess.run(["coqc", *flags, module.name], cwd=build, check=True)
        check_targets = [arg for name in [*[p.stem for p in generated], *MODULES]
                         for arg in ("-norec", name)]
        subprocess.run(["coqchk", "-silent", *flags, *check_targets],
                       cwd=build, check=True)
        inputs = [source_dir / name for name in ("cc_level.h", "cc_epoch.h", "cc_pack_row.h", "cc_candidate_row.h", "cc_row_builder.h",
                  "cc_overlap.h", "cc_overlap_policy.h", "cc_seed_policy.h", "cc_distance_bounds.h")]
        inputs.extend(source for _, source in translations)
        inputs.extend(proof_dir / "reference" / n for n in ("cc_level.h", "cc_epoch.h"))
        inputs.extend([*generated, *proofs])
        print(json.dumps({"checked_body": "detected",
                          "checked_paths": ["closes count mismatch", "closes full body",
                                            "dfs terminal depth without polling",
                                            "toggle full body", "flip full body",
                                            "closing_qubit full body",
                                            "dfs closed interior prefix without polling",
                                            "nonzero-word lowest-bit full body",
                                            "dfs one free move with physical lookup",
                                            "full index-order seed loop under callee contracts",
                                            "non-null policy parity return without polling",
                                            "physical leaf lookup without a supplied outcome",
                                            "leaf index construction from empty arrays",
                                            "leaf lookup for a physically constructed PCM table",
                                            "one-left DFS with the PCM table and a non-null policy",
                                            "two-move dispatch with open or closed first child",
                                            "restoration of excluded siblings in the native DFS",
                                            "recursive reports by remaining search depth",
                                            "CSR row append and unblocked candidate gathering",
                                            "validated rank exit for zero encoded qubits"],
                          "reference_c_commit": "b558c89eb4cf482da029e2076daa44ddb06e17c4",
                          "production_ast": "flag_level_ast",
                          "modules": list(MODULES), "sha256": {
            ("reference/" + path.name if path.parent == proof_dir / "reference" else path.name):
            digest(path) for path in inputs}}, indent=2))


if __name__ == "__main__":
    main()
