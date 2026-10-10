#!/usr/bin/env python3
"""Per-function machine-code comparison of two Mach-O binaries (arm64).
Instruction text is compared with absolute addresses removed: branch/call targets are kept as
<symbol+offset>, ADRP page addresses and the page-offset immediates that consume them are masked.
usage: fncmp.py BASE CAND [-v]"""
import sys, re, subprocess, hashlib
def funcs(path):
    out = subprocess.run(['objdump', '-d', '--no-show-raw-insn', path], capture_output=True, text=True, check=True).stdout
    fs = {}; order = []; cur = None; adrp = set()
    for line in out.splitlines():
        m = re.match(r'^([0-9a-f]+) <(.+)>:$', line)
        if m:
            cur = m.group(2).replace('__GLOBAL__sub_I_Solver.cc', '__GLOBAL__sub_I_<engine TU>').replace('__GLOBAL__sub_I_Engine.cc', '__GLOBAL__sub_I_<engine TU>')
            k = cur; i = 1
            while k in fs: i += 1; k = '%s#%d' % (cur, i)
            cur = k; fs[cur] = []; order.append((int(m.group(1), 16), cur)); adrp = set(); continue
        m = re.match(r'^\s*[0-9a-f]+:\s+(\S+)\s*(.*)$', line)
        if not m or cur is None: continue
        op, args = m.group(1), m.group(2)
        args = re.sub(r'0x[0-9a-f]+ <([^>]+)>', r'<\1>', args).replace('__GLOBAL__sub_I_Solver.cc', '__GLOBAL__sub_I_<engine TU>').replace('__GLOBAL__sub_I_Engine.cc', '__GLOBAL__sub_I_<engine TU>')
        args = re.sub(r';.*$', '', args).strip()
        regs = re.findall(r'\b([xw]\d+)\b', args)
        if op == 'adrp':
            args = regs[0] + ', PAGE'; adrp.add(regs[0].replace('w', 'x'))
        else:
            inbr = re.findall(r'\[([^\]]*)\]', args)
            src = [r.replace('w', 'x') for r in regs[1:]] if op not in ('str', 'strb', 'strh', 'stp') else [r.replace('w', 'x') for r in regs]
            src += [r.replace('w', 'x') for b in inbr for r in re.findall(r'\b([xw]\d+)\b', b)]
            if any(r in adrp for r in src) and '#' in args:
                args = re.sub(r'#0x[0-9a-f]+|#\d+', '#PAGEOFF', args)
            if regs and op not in ('str', 'strb', 'strh', 'stp', 'cmp', 'cbz', 'cbnz', 'tbz', 'tbnz', 'b', 'bl', 'br', 'blr', 'ret'):
                adrp.discard(regs[0].replace('w', 'x'))
        args = re.sub(r'\b0x1[0-9a-f]{8}\b', 'ADDR', args)
        fs[cur].append(op + ' ' + args)
    order.sort()
    return fs, [n for _, n in order]
b, bo = funcs(sys.argv[1]); c, co = funcs(sys.argv[2])
verbose = '-v' in sys.argv
onlyb = [n for n in bo if n not in c]; onlyc = [n for n in co if n not in b]
diff = [n for n in bo if n in c and b[n] != c[n]]
same = [n for n in bo if n in c and b[n] == c[n]]
print('functions: base=%d cand=%d common=%d identical=%d differing=%d only_base=%d only_cand=%d' % (
    len(b), len(c), len(same) + len(diff), len(same), len(diff), len(onlyb), len(onlyc)))
for n in onlyb: print('  only in base:', n)
for n in onlyc: print('  only in cand:', n)
for n in diff:
    print('  differs: %s (%d vs %d insns)' % (n, len(b[n]), len(c[n])))
    if verbose:
        import difflib
        for l in list(difflib.unified_diff(b[n], c[n], lineterm='', n=1))[:40]: print('    ' + l)
common = [n for n in co if n in b]
bpos = {n: i for i, n in enumerate([x for x in bo if x in c])}
moved = sum(1 for i, n in enumerate(common) if bpos[n] != i)
print('order: %d of %d common functions at a different rank in __text' % (moved, len(common)))
