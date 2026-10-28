import subprocess, sys, time, statistics, resource
F, core, c, reps = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
arms = sys.argv[5:]
data = {a: ([], [], []) for a in arms}
for i in range(reps):
    for arm in arms:   # interleaved
        a = arm.split() if arm != 'old' else []
        r0 = resource.getrusage(resource.RUSAGE_CHILDREN); t = time.perf_counter()
        subprocess.run(['taskset', '-c', core, F, '-engine=cc'] + a + [c], capture_output=True, stdin=subprocess.DEVNULL)
        w = time.perf_counter() - t; r1 = resource.getrusage(resource.RUSAGE_CHILDREN)
        data[arm][0].append(w); data[arm][1].append((r1.ru_utime + r1.ru_stime) - (r0.ru_utime + r0.ru_stime)); data[arm][2].append(r1.ru_minflt - r0.ru_minflt)
for arm in arms:
    w, cp, mf = data[arm]
    print(f"{c:14s} {arm:22s} wall {statistics.median(w)*1000:.2f} ms  cpu {statistics.median(cp)*1000:.2f} ms  minflt {statistics.median(mf):.0f}", flush=True)
