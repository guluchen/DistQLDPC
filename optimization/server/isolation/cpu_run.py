#!/usr/bin/python3 -I
"""Root-owned fixed-core lease supervisor. Benchmark commands run as yfc."""
import argparse
import ctypes
import fcntl
import json
import os
from pathlib import Path
import pwd
import signal
import subprocess
import sys
import time

USER = 'yfc'
CPUS = {102, 230}
CPU = 102
MAX_SECONDS = 7200
ROOT = Path('/sys/fs/cgroup')
GROUP = ROOT / 'distqldpc-bench'
STATE = Path('/run/distqldpc-bench')
LEASE = STATE / 'lease.json'


def cpulist(text):
    result = set()
    for part in text.strip().split(','):
        if not part:
            continue
        bounds = list(map(int, part.split('-')))
        if len(bounds) == 1:
            result.add(bounds[0])
        elif len(bounds) == 2 and bounds[0] <= bounds[1]:
            result.update(range(bounds[0], bounds[1] + 1))
        else:
            raise ValueError('Invalid CPU list')
    return result


def times():
    return {s.split()[0]: list(map(int, s.split()[1:9]))
            for s in Path('/proc/stat').read_text().splitlines() if s.startswith('cpu')}


def idle(a, b, key='cpu'):
    delta = [y-x for x, y in zip(a[key], b[key])]
    total = sum(delta)
    return 100*delta[3]/total if total > 0 else None


def capacity(value, count):
    return value is not None and value > 50 and len(CPUS) <= count*value/200


def write(name, value):
    (GROUP/name).write_text(str(value))


def identity(pid):
    # starttime avoids signalling a recycled PID during stale-lease recovery.
    return Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19]


def emit(event, **kwargs):
    print(json.dumps(dict(event=event, utc=time.time(), **kwargs)), flush=True)


def cleanup():
    if GROUP.exists():
        if (GROUP/'cgroup.procs').read_text().strip():
            write('cgroup.kill', '1')
            for _ in range(50):
                if not (GROUP/'cgroup.procs').read_text().strip():
                    break
                time.sleep(.1)
        if (GROUP/'cgroup.procs').read_text().strip():
            raise RuntimeError('Lease processes did not exit; isolation retained for recovery')
        write('cpuset.cpus.partition', 'member')
        GROUP.rmdir()
    LEASE.unlink(missing_ok=True)


def verify():
    if (GROUP/'cpuset.cpus.partition').read_text().strip() != 'isolated':
        raise RuntimeError('CPU partition is not valid isolated')
    for name in ('cpuset.cpus.effective', 'cpuset.cpus.exclusive.effective'):
        if cpulist((GROUP/name).read_text()) != CPUS:
            raise RuntimeError('Exclusive CPU set mismatch: '+name)
    if not CPUS <= cpulist((ROOT/'cpuset.cpus.isolated').read_text()):
        raise RuntimeError('Root does not report the isolated pair')
    for sibling in ROOT.iterdir():
        effective = sibling/'cpuset.cpus.effective'
        if sibling != GROUP and effective.exists() and CPUS & cpulist(effective.read_text()):
            raise RuntimeError('Another top-level cgroup retains reserved CPUs: '+str(sibling))


def prepare():
    if 'cpuset' not in (ROOT/'cgroup.subtree_control').read_text().split():
        raise RuntimeError('cpuset controller must already be enabled; refusing global controller change')
    if CPUS != cpulist(Path(f'/sys/devices/system/cpu/cpu{CPU}/topology/thread_siblings_list').read_text()):
        raise RuntimeError('Configured pair no longer matches one complete physical core')
    if not CPUS <= cpulist((ROOT/'cpuset.cpus.effective').read_text()):
        raise RuntimeError('Pair unavailable in parent partition')
    if CPUS & cpulist((ROOT/'cpuset.cpus.isolated').read_text()):
        raise RuntimeError('Pair already reserved by another partition')
    # Refuse to remove every CPU from any existing cgroup. Never edit its masks.
    for path in ROOT.rglob('cpuset.cpus.effective'):
        try:
            current = cpulist(path.read_text())
        except FileNotFoundError:
            continue
        if current and not current-CPUS:
            raise RuntimeError('Existing cgroup depends solely on this pair: '+str(path))
    a = times()
    time.sleep(5)
    b = times()
    count = len(cpulist(Path('/sys/devices/system/cpu/online').read_text()))
    value = idle(a, b)
    emit('preflight', idle_percent=value, reserved_cpus=sorted(CPUS), allocated_cpu=CPU)
    if not capacity(value, count):
        raise RuntimeError('Spare-capacity rule failed')
    if any(idle(a, b, 'cpu'+str(c)) is None or idle(a, b, 'cpu'+str(c)) < 95 for c in CPUS):
        raise RuntimeError('Pair busy at acquisition; no reservation made')
    GROUP.mkdir()
    write('cpuset.mems', (ROOT/'cpuset.mems.effective').read_text().strip())
    pair = ','.join(map(str, sorted(CPUS)))
    write('cpuset.cpus', pair)
    write('cpuset.cpus.exclusive', pair)
    write('cpuset.cpus.partition', 'isolated')
    verify()
    return count


def run(cwd, command):
    if not command or not os.path.isabs(command[0]) or not os.path.isabs(cwd):
        raise ValueError('Executable and cwd must be absolute paths')
    account = pwd.getpwnam(USER)
    groups = os.getgrouplist(USER, account.pw_gid)
    LEASE.write_text(json.dumps(dict(pid=os.getpid(), starttime=identity(os.getpid()),
        expires=time.time()+MAX_SECONDS, cpus=sorted(CPUS))))
    count = prepare()
    env = dict(PATH='/usr/local/bin:/usr/bin:/bin', HOME=account.pw_dir,
               USER=USER, LOGNAME=USER, LC_ALL='C', OMP_NUM_THREADS='1',
               OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')

    def child():
        write('cgroup.procs', os.getpid())
        os.sched_setaffinity(0, {CPU})
        os.setgroups(groups)
        os.setgid(account.pw_gid)
        os.setuid(account.pw_uid)
        # Do not permit setuid executables to regain privileges inside a lease.
        if ctypes.CDLL(None, use_errno=True).prctl(38, 1, 0, 0, 0) != 0:
            raise OSError('PR_SET_NO_NEW_PRIVS failed')
        os.chdir(cwd)

    emit('acquired', cpus=sorted(CPUS), uid=account.pw_uid, maximum_seconds=MAX_SECONDS)
    proc = subprocess.Popen(command, env=env, preexec_fn=child, start_new_session=True)
    deadline = time.monotonic()+MAX_SECONDS
    previous = times()
    while True:
        try:
            rc = proc.wait(timeout=2)
            return rc if rc >= 0 else 128-rc
        except subprocess.TimeoutExpired:
            current = times()
            value = idle(previous, current)
            emit('capacity', idle_percent=value, sibling_idle_percent=idle(previous,current,'cpu230'))
            previous = current
            if not capacity(value, count):
                raise RuntimeError('Spare-capacity rule lost; lease stopped')
            verify()
            if time.monotonic() > deadline:
                raise RuntimeError('Two-hour lease deadline exceeded')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest='action', required=True)
    r = sub.add_parser('run')
    r.add_argument('--cwd', required=True)
    r.add_argument('command', nargs=argparse.REMAINDER)
    sub.add_parser('status')
    sub.add_parser('reap')
    args = ap.parse_args()
    if os.geteuid() != 0:
        ap.error('Use the installed narrowly scoped sudo command')
    if args.action == 'reap' and 'SUDO_USER' in os.environ:
        ap.error('Recovery is reserved to the system service/root administrator')
    if os.environ.get('SUDO_USER') not in (None, USER):
        ap.error('Only the configured user is authorized')
    STATE.mkdir(mode=0o700, exist_ok=True)
    if args.action == 'status':
        emit('status', active=GROUP.exists(), lease=json.loads(LEASE.read_text()) if LEASE.exists() else None,
             partition=(GROUP/'cpuset.cpus.partition').read_text().strip() if GROUP.exists() else None)
        return 0
    with (STATE/'lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            if args.action == 'reap' and LEASE.exists():
                lease = json.loads(LEASE.read_text())
                if time.time() > lease['expires']:
                    try:
                        if identity(lease['pid']) == lease['starttime']:
                            os.kill(lease['pid'], signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                return 0
            raise RuntimeError('Another lease is active')
        cleanup()  # recover only our own fixed stale group, never another cgroup
        if args.action == 'reap':
            return 0
        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            signal.signal(sig, lambda *_: (_ for _ in ()).throw(RuntimeError('Lease interrupted')))
        try:
            command = args.command[1:] if args.command[:1] == ['--'] else args.command
            return run(args.cwd, command)
        finally:
            cleanup()
            emit('released', cpus=sorted(CPUS))


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print('ISOLATION_ERROR: '+str(exc), file=sys.stderr)
        sys.exit(1)
