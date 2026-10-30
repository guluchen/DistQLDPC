#!/usr/bin/env python3
"""Standalone finite BCH lower/upper certificate builder and verifier (GPL3+).

Verifier imports neither constructor, logical builder, matrix validator nor
distance engines. Root equations are explicit XORs of actual stored checks;
the Vandermonde argument proves the lower bound. A kernel detector with odd
pairing proves the actual upper word nontrivial. Raw solver fields are untouched.
"""
import argparse
from functools import lru_cache
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('bch_cases.json').read_text())
KINDS=('Hx','Hz','Gx','Gz')


def need(ok,message):
    if not ok:raise ValueError(message)


def parity(word):return bin(word).count('1')%2


def poly_mod(a,b):
    need(b>0,'zero polynomial modulus')
    aa={i for i in range(a.bit_length()) if (a >> i)&1}
    bb={i for i in range(b.bit_length()) if (b >> i)&1};degree=max(bb)
    while aa and max(aa)>=degree:
        shift=max(aa)-degree;aa.symmetric_difference_update({j+shift for j in bb})
    return sum(1 << i for i in aa)


def poly_gcd(a,b):
    while b:a,b=b,poly_mod(a,b)
    return a


def field_mul(a,b,p):
    """Coefficient-list convolution/reduction, independent of both input builders."""
    m=p.bit_length()-1
    need(m>=2 and 0<=a<(1 << m) and 0<=b<(1 << m),'invalid field element')
    result=[0]*(2*m-1)
    for i in range(m):
        for j in range(m):
            result[i+j]^=((a >> i)&1)&((b >> j)&1)
    for d in range(2*m-2,m-1,-1):
        if result[d]:
            for j in range(m+1):result[d-m+j]^=(p >> j)&1
    return sum(result[i] << i for i in range(m))


def field_pow(a,e,p):
    out=1
    while e:
        if e%2:out=field_mul(out,a,p)
        a=field_mul(a,a,p);e//=2
    return out


@lru_cache(None)
def irreducible(p):
    m=p.bit_length()-1
    if not 2<=m<=12 or p<=0 or not p&1:return False
    power=2
    for i in range(1,m+1):
        power=field_mul(power,power,p)
        if i<=m//2 and poly_gcd(power^2,p)!=1:return False
    return power==2


def read_matrix(path):
    rows=[];n=None
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith('#'):continue
        tokens=line.split();need(all(x in ('0','1') for x in tokens),'nonbinary physical matrix')
        if n is None:n=len(tokens)
        need(len(tokens)==n,'matrix width mismatch')
        rows.append(sum((x=='1') << i for i,x in enumerate(tokens)))
    need(rows and n,'empty physical matrix')
    return n,rows


def stem(case):return f'BCH_{case["n"]}_{case["k"]}_unknown'


def inputs(case,directory):
    matrices={};hashes={}
    for kind in KINDS:
        path=directory/(stem(case)+'_'+kind+'.txt');n,rows=read_matrix(path)
        need(n==case['n'],'case width mismatch');matrices[kind]=rows
        hashes[kind]=hashlib.sha256(path.read_bytes()).hexdigest()
    return matrices,hashes


def row_basis(rows):
    out={}
    for i,row in enumerate(rows):
        mask=1 << i
        while row:
            p=row.bit_length()-1
            if p in out:old,combo=out[p];row^=old;mask^=combo
            else:out[p]=(row,mask);break
    return out


def express(row,bb):
    coeff=0
    while row:
        p=row.bit_length()-1
        need(p in bb,'root equation is not a combination of physical stabilizers')
        old,mask=bb[p];row^=old;coeff^=mask
    return coeff


def root_equations(case,beta):
    n,m,p,delta=(case[k] for k in ('n','m','primitive_polynomial','delta'))
    need(1<n<=3000 and n%2 and 2<=delta<=min(64,n),'invalid finite source parameters')
    need(p.bit_length()==m+1 and irreducible(p),'field polynomial is not irreducible')
    need(((1 << m)-1)%n==0 and beta==field_pow(2,((1 << m)-1)//n,p),'wrong physical root convention')
    powers=[];seen=set();value=1
    for _ in range(n):
        need(value and value not in seen,'physical roots are not distinct/nonzero')
        powers.append(value);seen.add(value);value=field_mul(value,beta,p)
    need(value==1,'root does not close at n')
    equations=[]
    for j in range(1,delta):
        coordinate_rows=[0]*m
        for i in range(n):
            value=powers[(i*j)%n]
            for t in range(m):
                if (value >> t)&1:coordinate_rows[t] |= 1 << i
        equations+=coordinate_rows
    return equations


def pack_support(support,n):
    need(isinstance(support,list) and support and all(type(i) is int and 0<=i<n for i in support)
         and len(set(support))==len(support),'invalid physical support')
    return sum(1 << i for i in support)


def build(case,directory,word):
    matrices,hashes=inputs(case,directory);h=matrices['Hx']
    beta=field_pow(2,((1 << case['m'])-1)//case['n'],case['primitive_polynomial'])
    bb=row_basis(h);coefficients=[express(row,bb) for row in root_equations(case,beta)]
    support=sorted(word['support']);w=pack_support(support,case['n'])
    need(word['weight']==len(support),'upper word/support mismatch')
    if parity(w):detector=w;detector_origin='same odd kernel word'
    else:
        candidates=matrices['Gx' if word['half']=='X' else 'Gz']
        detector=next((d for d in candidates if parity(w&d)),None)
        need(detector is not None,'no actual logical detector');detector_origin='bundled logical detector'
    certificate=dict(schema_version=1,case_id=case['id'],stem=stem(case),
        n=case['n'],k=case['k'],m=case['m'],primitive_polynomial=case['primitive_polynomial'],
        delta=case['delta'],beta=beta,input_sha256=hashes,root_row_combinations=coefficients,
        word=dict(half=word['half'],support=support,origin=word.get('origin','retained actual word')),
        detector_support=[i for i in range(case['n']) if (detector >> i)&1],detector_origin=detector_origin)
    verify(case,directory,certificate)
    return certificate


def verify(case,directory,certificate):
    need(certificate['schema_version']==1 and certificate['case_id']==case['id']
         and certificate['stem']==stem(case),'wrong certificate/case identity')
    for key in ('n','k','m','primitive_polynomial','delta'):
        need(certificate[key]==case[key],'frozen certificate parameter changed')
    matrices,hashes=inputs(case,directory)
    need(certificate['input_sha256']==hashes,'physical input identity mismatch')
    h=matrices['Hx'];need(h==matrices['Hz'],'only actual identity-XZ BCH class is certified')
    rank=len(row_basis(h));need(case['n']-2*rank==case['k']>0,'quantum dimension mismatch')
    need(len(matrices['Gx'])==case['k']==len(matrices['Gz']),'logical row count mismatch')
    need(not any(parity(a&b) for a in h for b in h),'CSS self-orthogonality failed')
    roots=root_equations(case,certificate['beta']);combos=certificate['root_row_combinations']
    need(len(combos)==len(roots),'missing consecutive root equation')
    for mask,expected in zip(combos,roots):
        need(type(mask) is int and 0<=mask<(1 << len(h)),'invalid row-combination mask')
        reconstructed=0
        for i,row in enumerate(h):
            if (mask >> i)&1:reconstructed^=row
        need(reconstructed==expected,'root-equation combination mismatch')
    need(certificate['word']['half'] in ('X','Z'),'invalid physical Pauli half')
    w=pack_support(certificate['word']['support'],case['n'])
    d=pack_support(certificate['detector_support'],case['n'])
    need(not any(parity(row&w) for row in h),'upper word has nonzero syndrome')
    need(not any(parity(row&d) for row in h),'detector is not in the opposite parity kernel')
    need(parity(w&d)==1,'word is not independently detected outside stabilizer space')
    upper=len(certificate['word']['support']);lower=case['delta']
    need(upper>=lower,'actual word contradicts Vandermonde certificate')
    return dict(stem=stem(case),n=case['n'],k=case['k'],certificate_lower=lower,
                actual_verified_upper=upper,certificate_exact=lower if lower==upper else None,
                source_published_exact=case.get('published_exact'),
                proof='independent physical-root XOR certificate + field Vandermonde + kernel detector',
                root_equations_checked=len(roots),rank_Hx_Hz=rank,
                input_sha256=hashes,raw_engine_fields_unchanged=True,
                global_novelty_asserted=False,logical_word_half=certificate['word']['half'])


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    mode=ap.add_mutually_exclusive_group(required=True)
    mode.add_argument('--build',type=Path);mode.add_argument('--verify',type=Path)
    ap.add_argument('--matrices',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--audit',type=Path,default=ROOT/'optimization/experiments/GH-207/raw/actions/default/audit.json')
    ap.add_argument('--out',type=Path)
    a=ap.parse_args();results=[]
    if a.build:
        a.build.mkdir(parents=True,exist_ok=False)
        observations={r['stem']:r for r in json.loads(a.audit.read_text())}
        for case in CASES:
            best=min(observations[stem(case)]['witnesses'],key=lambda w:w['weight'])
            cert=build(case,a.matrices,best)
            (a.build/(stem(case)+'.json')).write_text(json.dumps(cert,indent=2)+'\n')
            results.append(verify(case,a.matrices,cert))
        (a.build/'VERDICT.json').write_text(json.dumps(results,indent=2)+'\n')
    else:
        expected={stem(case)+'.json' for case in CASES}|{'VERDICT.json'}
        need({p.name for p in a.verify.glob('*.json')}==expected,'unexpected certificate selection')
        for case in CASES:
            cert=json.loads((a.verify/(stem(case)+'.json')).read_text())
            results.append(verify(case,a.matrices,cert))
    text=json.dumps(results,indent=2)+'\n'
    if a.out:a.out.write_text(text)
    else:print(text,end='')


if __name__=='__main__':main()
