import re,glob,os,statistics as st
S='/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/'
def diag(f):
    if not os.path.exists(f): return None
    m=re.search(r'c DIAG \w cap \d+ \w+: cpu ([\d.]+) conflicts (\d+)',open(f,errors='replace').read())
    return int(m.group(2)) if m else None
def c5(md,arm,s):
    d={}
    for m in re.finditer(r'FRONTIER (\w) cap (\d+) \w+: conflicts (\d+)',open(S+f'c5logs/logs/s5.TN_216_4_18.{md}.{arm}.s{s}.log').read()):
        if int(m.group(2))>=16: d[m.group(1)+m.group(2)]=int(m.group(3))
    return d
G=S+'g1pull/'
print('TN_216: v1 / off(12b3e05) conflicts; auto/off for reference')
for md in ('no-card','card-mto'):
    rt=[];rz=[];ra=[]
    for s in range(5):
        off=c5(md,'main',s); aut=c5(md,'cand',s); v={}
        for p in ('X16','Z16','X17','Z17'):
            f=G+f'TN216_{p}_{md}_s{s}_v1.log'
            if md=='no-card' and s==0:
                f={'X16':S+'v1pull/TN216_X16_v1.log','Z16':S+'v1pull/TN216_Z16_v1.log','X17':S+'v1pull/TN216_X17_v1.log','Z17':S+'v1pull/TN216_Z17_v1.log'}[p]
            v[p]=diag(f)
        if None in v.values() or len(off)<4: print(md,s,'incomplete',v); continue
        tot=sum(v.values())/sum(off.values()); z=(v['Z16']+v['Z17'])/(off['Z16']+off['Z17']); a=sum(aut.values())/sum(off.values())
        rt.append(tot); rz.append(z); ra.append(a)
        print(md,'s%d'%s,'total %.3f  Z %.3f  per-probe %s | auto total %.3f'%(tot,z,' '.join('%s:%.2f'%(p,v[p]/off[p]) for p in ('X16','Z16','X17','Z17')),a))
    if rt: print(md,'MEDIAN total %.3f Z %.3f (auto %.3f)'%(st.median(rt),st.median(rz),st.median(ra)))
print('TN_180 X16: off / auto / v1 conflicts, gain kept = (off-v1)/(off-auto)')
known={('card-mto',0):{'off':13295888,'auto':6924113,'v1':6544783},('card-mto',1):{'off':12027889,'auto':5724700},('card-mto',2):{'off':9499484,'auto':6272505},('no-card',0):{'auto':6471090,'off':7977909}}
for md in ('no-card','card-mto'):
    ks=[]
    for s in range(5):
        k=dict(known.get((md,s),{}))
        for a in ('off','auto','v1'):
            if a not in k:
                x=diag(G+f'TN180_X16_{md}_s{s}_{a}.log')
                if x: k[a]=x
        if len(k)<3: print(md,s,'incomplete',k); continue
        kept=(k['off']-k['v1'])/(k['off']-k['auto']) if k['off']!=k['auto'] else float('nan')
        ks.append(k['v1']/k['auto'])
        print(md,'s%d'%s,'off %.2fM auto %.2fM v1 %.2fM  v1/auto %.2f v1/off %.2f gain kept %.2f'%(k['off']/1e6,k['auto']/1e6,k['v1']/1e6,k['v1']/k['auto'],k['v1']/k['off'],kept))
    if ks: print(md,'MEDIAN v1/auto %.3f'%st.median(ks))
