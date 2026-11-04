import sys,re,glob,os
for f in sorted(sum([glob.glob(a) for a in sys.argv[1:]],[])):
    for line in open(f,errors='replace'):
        if 'c DIAG ' not in line or 'DIAGPROBE' in line: continue
        m=re.search(r'c DIAG (\w) cap (\d+) (\w+): (.*)',line)
        if not m: continue
        kv=dict(zip(m.group(4).split()[0::2],m.group(4).split()[1::2]))
        g=lambda k: float(kv.get(k,0))
        c=max(g('conflicts'),1)
        print('%-28s %s%-3s cpu %8.1f confl %9d us/cf %6.1f lkp/cf %6.0f p/cf %5.0f look/cf %4.2f ovp/cf %5.3f ovpL/cf %5.3f ovcf%% %5.2f anaov%% %5.2f lrn/cf %5.2f tM %6.1f tL %6.1f' % (
            os.path.basename(f)[:28], m.group(1), m.group(2), g('cpu'), c, 1e6*g('cpu')/c, g('lkprops')/c, g('props')/c, g('lookahead')/c,
            (g('ovprops')-g('ovpropsL'))/c, g('ovpropsL')/c, 100*g('ovconfl')/c, 100*g('anaov')/max(g('anares'),1), g('learntlits')/c, g('tM'), g('tL')))
