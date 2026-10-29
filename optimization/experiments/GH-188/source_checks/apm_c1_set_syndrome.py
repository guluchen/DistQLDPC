#!/usr/bin/env python3
"""Second fixed-source-word check using explicit sets, no packed GF2 matrix."""
import json
P=216
F=[(73,87),(199,75),(181,24),(127,213),(199,75),(181,186)]
G=[(97,188),(73,204),(25,140),(13,154),(73,168),(25,68)]
Z={(0,204),(1,26),(2,136),(3,60),(4,180),(5,100),(7,183),(8,78),(10,111),(11,168)}
bad=[]
for i in range(3):
    for t in range(P):
        incident={(j,(F[(j-i)%6][0]*t+F[(j-i)%6][1])%P) for j in range(6)}|{(6+j,(G[(j-i)%6][0]*t+G[(j-i)%6][1])%P) for j in range(6)}
        overlap=sorted(incident&Z)
        if len(overlap)%2:bad.append(dict(check=[i,t],odd_intersection=overlap))
print(json.dumps(dict(method='independent explicit sets, source row convention',number_of_odd_checks=len(bad),odd_checks=bad),indent=2))
