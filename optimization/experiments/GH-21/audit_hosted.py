"""Audit saved hosted scientific results. This does not run any solver."""
import hashlib
import json
from pathlib import Path

def audit(directory):
    directory=Path(directory)
    report=json.loads((directory/'report/result.json').read_text())
    assert len(report['rows'])==4 and report['scientific_semantics_match']
    assert report['timing_is_ci_signal_only']
    assert {(r['stem'],r['config']) for r in report['rows']}=={
        (stem,mode) for stem in ['LP_136_32_4','BB_108_8_10'] for mode in ['no-card','card-mto']}
    for row in report['rows']:
        assert row['same_semantics']
        expected=4 if row['stem']=='LP_136_32_4' else 10
        for version in ['baseline','candidate']:
            result=row[version]
            assert result['returncode']==0 and not result['timed_out']
            assert all(result[k]==expected for k in ['d','objective','d_lb','d_ub'])
    assert hashlib.sha256((directory/'artifact.zip').read_bytes()).hexdigest()==(
        '3d15eca87b8990a4fc667ab485626491bdc615405d65fa3bdca52b401d569822')
    print('AUDIT_PASS: hosted4pairs8solves/science/artifact hash; timing not performance evidence')

if __name__=='__main__':
    import sys
    audit(sys.argv[1])
