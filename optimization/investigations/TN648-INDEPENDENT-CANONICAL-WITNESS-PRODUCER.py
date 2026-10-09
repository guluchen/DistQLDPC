"""Bounded canonical Git/GF(2) evidence only; no solver or compiled code."""
import ctypes,hashlib,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent;REPO=ROOT/'CORRECTED-BASELINE-72D1'
BASE='72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7'
STEM='TN_648_10_71'
def git(*args):return subprocess.check_output(['git','-C',str(REPO),*args])
def digest(b):return hashlib.sha256(b).hexdigest()
def dot(a,b):return (a&b).bit_count()&1
def matrix(data):
    rows=[]
    for line in data.decode('utf-8').splitlines():
        if not line.strip() or line.lstrip().startswith('#'):continue
        bits=[int(x) for x in line.split()];assert len(bits)==648 and set(bits)<={0,1}
        rows.append(sum(x<<i for i,x in enumerate(bits)))
    assert rows;return rows
def basis(rows):
    out={}
    for index,row in enumerate(rows):
        v=row;combination=1<<index
        while v:
            p=v.bit_length()-1
            if p in out:v^=out[p][0];combination^=out[p][1]
            else:out[p]=(v,combination);break
    for p,(v,combination) in out.items():
        reconstructed=0
        for i,r in enumerate(rows):
            if (combination>>i)&1:reconstructed^=r
        assert reconstructed==v and v.bit_length()-1==p
    return out
def reduce(v,b):
    residual=v;used=[]
    for p in sorted(b,reverse=True):
        if (residual>>p)&1:residual^=b[p][0];used.append(p)
    return residual,used
k=ctypes.windll.kernel32;k.GetCurrentProcess.restype=ctypes.c_void_p
k.GetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.POINTER(ctypes.c_size_t),ctypes.POINTER(ctypes.c_size_t)]
k.SetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.c_size_t]
h=k.GetCurrentProcess();m=ctypes.c_size_t();s=ctypes.c_size_t()
assert k.GetProcessAffinityMask(h,ctypes.byref(m),ctypes.byref(s)) and k.SetProcessAffinityMask(h,1)
try:
    source=git('show',BASE+':src/core/distqldpc.cc').decode('utf-8')
    assert 'if (getm(Hx, r, i)) lits.push_back(mkLit(off_z + i));' in source
    assert 'if (getm(Hz, r, i)) lits.push_back(mkLit(off_x + i));' in source
    assert 'if (getm(Gx, j, i)) lits.push_back(mkLit(off_x + i));' in source
    assert 'if (getm(Gz, j, i)) lits.push_back(mkLit(off_z + i));' in source
    assert 'c1.push_back(~wi); c1.push_back(xi);  c1.push_back(zi);' in source
    mats={};identity={}
    for name in ['Hx','Hz','Gx','Gz']:
        path='data/matrices/'+STEM+'_'+name+'.txt';data=git('show',BASE+':'+path);mats[name]=matrix(data)
        identity[name]=dict(path=path,Git_blob=git('rev-parse',BASE+':'+path).decode().strip(),canonical_sha256=digest(data),bytes=len(data),rows=len(mats[name]),columns=648)
    bases={name:basis(rows) for name,rows in mats.items()}
    css_bad=[(i,j) for i,x in enumerate(mats['Hx']) for j,z in enumerate(mats['Hz']) if dot(x,z)]
    assert not css_bad
    logical_bad={name:[(i,j) for i,g in enumerate(mats[name]) for j,hrow in enumerate(mats['Hx' if name=='Gx' else 'Hz']) if dot(g,hrow)] for name in ['Gx','Gz']}
    assert not any(logical_bad.values())
    witnesses=[]
    for sector,name,indices,commute,span,dual in [('X','Gz',[0,2],'Hz','Hx','Gx'),('Z','Gx',[0,1,2],'Hx','Hz','Gz')]:
        for index in indices:
            v=mats[name][index];bad=[j for j,row in enumerate(mats[commute]) if dot(v,row)]
            remainder,pivots=reduce(v,bases[span]);odd=[j for j,row in enumerate(mats[dual]) if dot(v,row)]
            assert not bad and remainder!=0 and odd
            assert len(basis(mats[span]+[v]))==len(bases[span])+1
            x,z=(v,0) if sector=='X' else (0,v)
            syndrome_x=[dot(row,x) for row in mats['Gx']];syndrome_z=[dot(row,z) for row in mats['Gz']]
            assert any(syndrome_x+syndrome_z) and x|z
            witnesses.append(dict(sector=sector,source_matrix=name,row_index_zero_based=index,individual_row_not_XOR_combination=True,witness_bits_column0_first=''.join(str((v>>i)&1) for i in range(648)),support_zero_based=[i for i in range(648) if (v>>i)&1],Pauli_OR_weight=(x|z).bit_count(),commutation_matrix=commute,commutation_rows_checked=len(mats[commute]),noncommuting_rows=bad,stabilizer_span_matrix=span,stabilizer_rank=len(bases[span]),rank_with_witness=len(bases[span])+1,GF2_reduction_residual_hex=hex(remainder),GF2_reduction_basis_pivots_used=pivots,nonmember=True,anticommuting_dual_matrix=dual,anticommuting_dual_row_indices=odd,encoded_Gx_dot_x=syndrome_x,encoded_Gz_dot_z=syndrome_z,encoded_nontriviality=True))
    weights=[r['Pauli_OR_weight'] for r in witnesses];assert weights==[52,52,54,54,54]
    report=dict(schema='DISTQLDPC_CANONICAL_CSS_WITNESS_UPPER_BOUND_AUDIT',status='VERIFIED_MATERIAL_NAMED_DISTANCE_ANOMALY',commit=BASE,code=STEM,n=648,matrix_identities=identity,source_orientation=dict(core_Git_blob=git('rev-parse',BASE+':src/core/distqldpc.cc').decode().strip(),core_canonical_sha256=digest(source.encode()),Hx_tests_z=True,Hz_tests_x=True,Gx_tests_x=True,Gz_tests_z=True,Pauli_weight='popcount(x OR z)'),all_Hx_Hz_commutation_checked=True,all_logical_rows_commute_correct_sector=True,ranks={name:len(b) for name,b in bases.items()},witnesses=witnesses,certified_distance_upper_bound=min(weights),exact_distance=None,filename_distance_label=71,contradiction='Canonical bundled matrices admit nontrivial Pauli weight52, so their distance cannot equal71.',external_escalation='https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6078813000',scope='Five specified INDIVIDUAL logical rows, not a solver search, not pair/triple combinations.',data_changed=False,groundtruth_changed=False,scientific_semantics_changed=False,solver_or_compiler_run=False,GH83_failure=False,requires_PI_resolution_of_data_vs_named_label=True,auditor_source_sha256=digest(Path(__file__).read_bytes()))
    path=ROOT/'TN648-independent-canonical-witness-check.json';path.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(status=report['status'],weights=weights,upper_bound=min(weights),exact_distance=None,ranks=report['ranks'],report_sha256=digest(path.read_bytes()),source_sha256=report['auditor_source_sha256'])))
finally:assert k.SetProcessAffinityMask(h,m)
