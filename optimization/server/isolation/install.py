#!/usr/bin/python3 -I
"""Install the reviewed fixed-core helper; requires one interactive sudo."""
import argparse
import hashlib
import os
from pathlib import Path
import pwd
import stat
import subprocess
import tempfile

HELPER_SHA256 = '0bf26454f93bdb2d1d3973d212f141c1e3af174c4954d35df2ab98abddee0229'
HELPER = Path('/usr/local/sbin/distqldpc-cpu-run')
SUDOERS = Path('/etc/sudoers.d/distqldpc-bench')
SERVICE = Path('/etc/systemd/system/distqldpc-bench-recover.service')
TIMER = Path('/etc/systemd/system/distqldpc-bench-recover.timer')


def secure_parent(path):
    info = path.parent.stat()
    if info.st_uid != 0 or info.st_mode & 0o022 or path.parent.is_symlink() or not path.parent.is_dir():
        raise RuntimeError('Installation directory must be root-owned and not writable by others: '+str(path.parent))


def ensure_helper_directory():
    directory = HELPER.parent
    if directory.is_symlink():
        raise RuntimeError('Refusing symlink installation directory: '+str(directory))
    if not directory.exists():
        # Only create this one missing directory under a verified root-owned
        # parent. Never recursively create parents or change existing permissions.
        secure_parent(directory)
        directory.mkdir(mode=0o755)
        os.chmod(directory, 0o755)
    secure_parent(HELPER)


def atomic(path, data, mode):
    secure_parent(path)
    fd, name = tempfile.mkstemp(prefix='.distqldpc-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.chown(name, 0, 0)
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def command(*argv):
    subprocess.run(argv, check=True)


def content():
    source = Path(__file__).with_name('cpu_run.py').read_bytes()
    if hashlib.sha256(source).hexdigest() != HELPER_SHA256:
        raise RuntimeError('Reviewed helper checksum mismatch; refusing installation')
    sudoers = ('# Fixed-core helper only; all benchmark commands drop to yfc.\n'
        'yfc ALL=(root) NOPASSWD: NOSETENV: /usr/local/sbin/distqldpc-cpu-run run *, '
        '/usr/local/sbin/distqldpc-cpu-run status\n').encode()
    service = b'''[Unit]
Description=Recover stale DistQLDPC fixed-core CPU leases
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/distqldpc-cpu-run reap
'''
    timer = b'''[Unit]
Description=Check stale DistQLDPC CPU leases every minute
[Timer]
OnBootSec=60
OnUnitActiveSec=60
AccuracySec=5
Unit=distqldpc-bench-recover.service
[Install]
WantedBy=timers.target
'''
    return {HELPER:(source,0o755), SUDOERS:(sudoers,0o440),
            SERVICE:(service,0o644), TIMER:(timer,0o644)}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('action', choices=('install','uninstall'))
    args = ap.parse_args()
    if os.geteuid() != 0:
        ap.error('Run this installer with sudo')
    pwd.getpwnam('yfc')
    files = content()
    if args.action == 'install':
        ensure_helper_directory()
    elif not any(path.exists() or path.is_symlink() for path in files):
        print('Already uninstalled')
        return
    for path, (data, mode) in files.items():
        secure_parent(path)
        if path.is_symlink():
            raise RuntimeError('Refusing symlink target: '+str(path))
        if path.exists():
            info = path.stat()
            if info.st_uid != 0 or stat.S_IMODE(info.st_mode) != mode or path.read_bytes() != data:
                raise RuntimeError('Existing target differs; refusing to overwrite/delete: '+str(path))
    existing = [p.exists() for p in files]
    if any(existing) and not all(existing):
        raise RuntimeError('Partial installation exists; manual inspection required')
    if args.action == 'uninstall':
        if not any(existing):
            print('Already uninstalled')
            return
        command(str(HELPER), 'reap')
        if Path('/sys/fs/cgroup/distqldpc-bench').exists():
            raise RuntimeError('Active lease; wait for it to finish before uninstalling')
        command('/usr/bin/systemctl','disable','--now',TIMER.name)
        for p in files:
            p.unlink()
        command('/usr/bin/systemctl','daemon-reload')
        print('Uninstalled; CPU pair is released')
        return
    if Path('/sys/fs/cgroup/distqldpc-bench').exists() and not all(existing):
        raise RuntimeError('Cgroup name already in use; refusing installation')
    # Validate exact sudo rule before changing the server.
    fd, checkname = tempfile.mkstemp(prefix='distqldpc-sudoers-',dir='/run')
    try:
        with os.fdopen(fd,'wb') as f:
            f.write(files[SUDOERS][0])
        os.chmod(checkname,0o440)
        command('/usr/sbin/visudo','-cf',checkname)
    finally:
        Path(checkname).unlink(missing_ok=True)
    new = []
    try:
        for path,(data,mode) in files.items():
            if not path.exists():
                atomic(path,data,mode)
                new.append(path)
        command('/usr/bin/systemctl','daemon-reload')
        command('/usr/bin/systemctl','enable','--now',TIMER.name)
        command('/usr/sbin/visudo','-c')
    except Exception:
        if new:
            subprocess.run(['/usr/bin/systemctl','disable','--now',TIMER.name],check=False)
            for p in new:
                p.unlink(missing_ok=True)
            subprocess.run(['/usr/bin/systemctl','daemon-reload'],check=False)
        raise
    print('INSTALLATION_COMPLETE: restricted passwordless helper and recovery timer installed',flush=True)
    command(str(HELPER),'status')
    print('Next: validate a short unprivileged lease through sudo -n; no further password required.',flush=True)


if __name__ == '__main__':
    main()
