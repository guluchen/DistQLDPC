# Rotated toric [[10,2,3]] correctness benchmark

`TORIC_10_2_3` is the ten-qubit rotated toric CSS code. The check supports
are transcribed in the column order of the CSS tableau linked from the
[Error Correction Zoo entry](https://errorcorrectionzoo.org/c/xzzx_10_2_3).
See also the [published construction](https://doi.org/10.1103/PhysRevA.88.012311).
The local fixture is CSS, not the locally Clifford-equivalent non-CSS XZZX tableau.
All support indices below are zero-based.

- Hx: {0,2,3,9}, {1,2,4,5}, {3,4,6,7}, {5,6,8,9}.
- Hz: {0,1,3,4}, {2,3,5,6}, {4,5,7,8}, {0,6,7,9}.
- Gx: {0,1,2}, {0,3,7}.
- Gz: {1,2,3}, {0,1,2,6}.

The repository convention is **Gx = Z logicals** in ker(Hx)/row(Hz),
**Gz = X logicals** in ker(Hz)/row(Hx). These are quotient bases, not
necessarily a canonical paired logical basis. Hx and Hz commute, each has
rank 4, and the logical pairing has rank 2. Exhaustive enumeration of all
1,024 binary vectors per half proves dX = dZ = 3.

```sh
make --jobs=2 bin/distqldpc
python3 tests/test_rotated_toric.py
./bin/distqldpc -engine=cc data/matrices/untiered/TORIC_10_2_3
./bin/distqldpc -engine=maxsat data/matrices/untiered/TORIC_10_2_3
```

Both solver runs should report `o 3`. This is a correctness fixture, not a
performance or physical-layout claim. In particular, a torus drawing is
not an implementation on a planar square grid with one dedicated ancilla
per check and no SWAPs. No such embedding is supplied here.

The fixture stays untiered pending server measurements and PI tier approval;
no tier panel, QDistSAT mirror, or historical MANIFEST is changed.
