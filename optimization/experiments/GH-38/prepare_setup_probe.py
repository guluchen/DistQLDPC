"""DISABLED GH38 setup/probe planner. No installer/compiler execution implemented.

The future guarded supervisor must be reviewed, the sole-host assignment frozen,
and all exact metadata/dependency/runtime conditions checked before enabling work.
This template never runs subprocesses, network downloads or package extraction.
"""
import argparse,hashlib,json
from pathlib import Path

ASSIGNED_URL='HOST_SLOT_NOT_ASSIGNED'
GUARDED_EXECUTION_REVIEWED=False
MIRROR='https://mirrors.kernel.org/sourceware/cygwin/'
INSTALLER_SHA512='6acea47c59781c9e7f544a18d53935d59df6e44d5d52ac95ee165671b8e388820455eebf30ccc7d254b00c3d0eb694269a0f8dc84b17944c1f355dac9c5aafcc'

def plan(workspace):
    workspace=Path(workspace).resolve();here=Path(__file__).resolve().parent
    metadata=json.loads((here/'PACKAGE-METADATA.json').read_text(encoding='utf-8'))
    assert metadata['packages']['clang']['version']=='22.1.8-3'
    packages=[]
    for name in ['clang','libclang22.1','libllvm22.1']:
        row=metadata['packages'][name];relative,size,digest=row['install'].split()
        assert relative.startswith('x86_64/release/') and '..' not in Path(relative).parts
        assert len(digest)==128 and all(c in '0123456789abcdef' for c in digest)
        packages.append(dict(name=name,version=row['version'],url=MIRROR+relative,
                             bytes=int(size),sha512=digest,dependencies=row['depends2']))
    return dict(status='PLAN_ONLY / NOT_EXECUTABLE',assignment=ASSIGNED_URL,
        immutable_runtime=str(workspace/'E004-windows-runtime/cygwin'),
        own_overlay=str(workspace/'GH38-compiler-overlay-01'),
        packages=packages,three_archives_bytes=sum(p['bytes'] for p in packages),
        dependency_closure='UNRESOLVED: libxml2/libedit0/python3 etc must be resolved/pinned; no assumption these three archives are sufficient',
        installer=dict(path=str(workspace/'E004-windows-runtime/setup-x86_64.exe'),sha512=INSTALLER_SHA512,
            policy='if used only --no-admin/quiet/no-shortcuts/no-desktop/no-startmenu/no-replaceonreboot with OWN fresh root/cache; signed metadata verification enabled'),
        mandatory_guard='reviewed helper oneCPU Job / >50% global spare / <=half spare / active2s guard / bounded ownPID cleanup / all4settingsrestore',
        mandatory_proof='all old E004 bytes unchanged; actual target/macro/language/header/GNU rtlib/linker/library resolution equal; no semantic flags/source/runtime replacement',
        compiler_probe='future assigned --version/-dumpmachine/-### and empty-TU macros only, actual argv frozen; no solver/build/performance implied')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace',type=Path,required=True)
    parser.add_argument('--assignment',required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    assert ASSIGNED_URL!='HOST_SLOT_NOT_ASSIGNED','No host assignment; template disabled'
    assert args.assignment==ASSIGNED_URL
    assert GUARDED_EXECUTION_REVIEWED,'No reviewed executable guarded setup supervisor; planner only'
    raise SystemExit('Execution intentionally not implemented; do not silently enable package/compiler work')

if __name__=='__main__':main()
