#!/usr/bin/env python3
"""Independent GF(2) support, syndrome, quotient and logical-detector checks."""
from validate_css import basis,contains,dot


def verify_witness(n,matrices,half,support):
    if half not in ('X','Z') or not support or len(set(support))!=len(support) or min(support)<0 or max(support)>=n:
        raise ValueError('invalid witness support/half')
    hx,hz,gx,gz=matrices
    parity,stab,detectors=(hz,hx,gx) if half=='X' else (hx,hz,gz)
    word=sum(1 << q for q in support)
    if any(dot(word,r) for r in parity) or contains(basis(stab),word):
        raise ValueError('not a nontrivial logical witness')
    if not any(dot(word,r) for r in detectors):raise ValueError('no logical detector')

