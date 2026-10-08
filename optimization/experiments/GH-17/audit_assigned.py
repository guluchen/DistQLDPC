"""Read-only independent audit of retained GH17 validation evidence."""
import hashlib
import json
import pathlib

HERE=pathlib.Path(__file__).resolve().parent
raw=HERE/"raw/windows-assigned-02"
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
load=lambda p:json.loads(p.read_text(encoding="utf-8"))
summary=load(raw/"summary.json")
identity=load(raw/"identity.json")
assert summary["Tier0"]=="LOCAL_PASS" and summary["status"]=="PREPARATORY_COMPLETE"
assert identity["candidate"]=="191de6849357574c830e14992a7afe9615dad320"
for manifest_path in [raw/"SHA256.json",raw/"tier0/SHA256.json",raw/"allocation/SHA256.json"]:
    for relative,digest in load(manifest_path).items():
        path=manifest_path.parent/pathlib.Path(relative.replace("\\","/"))
        if path.exists():assert sha(path)==digest,relative
        else:
            # Published source/raw logs are portable; the two locally retained
            # compiled probes are hash-only artifacts, explicitly not in Git.
            assert path.name in ["baseline-probe.exe","candidate-probe.exe"],relative
assert (raw/"tier0/core-trace-baseline.stdout").read_bytes()==(raw/"tier0/core-trace-candidate.stdout").read_bytes()
assert len((raw/"tier0/core-trace-baseline.stdout").read_text().splitlines())==4096*3+2
assert identity["test_source_sha256"]==sha(HERE/"test_core_scratch.cc")
for row in load(raw/"resources.json"):
    assert row["eligible"] and row["idle_percent"]>50 and row["half_spare_logical_cpus"]>=1
    assert row["affinity"]==identity["selection"]["mask"]
for snapshot in load(raw/"descendants.json"):
    assert all(r["mask"]==identity["selection"]["mask"] and r["priority_class"]==0x8000 for r in snapshot["records"])
for p in raw.rglob("*.command.json"):
    if "diagnostic-baseline" not in p.parts:
        row=load(p);assert not row.get("abort") and row.get("owned_descendants_remaining")==[],p
for name in ["job_limit_released","affinity_restored","sleep_requirement_restored","priority_restored"]:
    assert summary["cleanup"][name],name
assert summary["cleanup"]["final_mask"]==65535 and summary["cleanup"]["final_priority_class"]==32
assert len(load(raw/"job-pids-before-release.json"))==1
for p in raw.glob("owned-cleanup-*.json"):assert load(p)["confirmed"] and not load(p)["remaining"]
counter_rows=load(raw/"allocation/counters.json")
assert len(counter_rows)==4
allocated=sum(c["baseline_allocations"] for r in counter_rows for c in r["counters"])
reused=sum(c["predicted_reuse_allocations"] for r in counter_rows for c in r["counters"])
assert allocated==328 and reused==319
assert max(c["baseline_peak_capacity"] for r in counter_rows for c in r["counters"])==2
hosted=HERE/"raw/hosted-191de68"
assert sha(hosted/"artifact.zip")=="d859383ee5958781cb5334c08c422157060128644f5a16cf35454c28857788f2"
pilot=load(hosted/"report/result.json")
assert pilot["scientific_semantics_match"] and pilot["timing_is_ci_signal_only"] and len(pilot["rows"])==4
for row in pilot["rows"]:
    assert row["same_semantics"]
    exact=4 if row["stem"]=="LP_136_32_4" else 10
    for version in ["baseline","candidate"]:
        r=row[version]
        assert r["returncode"]==0 and not r["timed_out"]
        assert all(r[k]==exact for k in ["d","objective","d_lb","d_ub"])
print("AUDIT_PASS: exact manifests, production-state traces, identities, scientific results, capacity/affinity/priority and owned cleanup")
