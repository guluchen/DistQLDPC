"""Owned-process logging/watchdog helpers, not a CPU lease or performance harness."""
import hashlib
import json
import os
import pathlib
import signal
import subprocess


def sha(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()


def save(path, value):
    pathlib.Path(path).write_text(json.dumps(value, indent=2), encoding="utf-8")


def cygpath(value):
    value=str(value).replace("\\", "/")
    if value.startswith("-dump-wcnf="):
        return "-dump-wcnf="+cygpath(value[len("-dump-wcnf="):])
    if len(value)>2 and value[1]==":":
        return "/cygdrive/"+value[0].lower()+value[2:]
    return value


def run(argv, cwd, out, label, timeout, cygwin=False):
    argv=list(map(str,argv))
    if cygwin:
        argv=[argv[0]]+[cygpath(value) for value in argv[1:]]
    env=dict(os.environ, LC_ALL="C",OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1")
    process=subprocess.Popen(argv,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                             env=env,start_new_session=(os.name=="posix"))
    timed_out=False
    try:
        stdout,stderr=process.communicate(timeout=timeout)
    except BaseException:
        # Terminate only the process tree launched by this helper, including
        # the forked solver. Windows callers must also use the assigned Job/
        # capacity wrapper; this function does NOT grant resource ownership.
        if os.name=="posix":
            try: os.killpg(process.pid,signal.SIGKILL)
            except ProcessLookupError: pass
        else:
            subprocess.run(["taskkill","/PID",str(process.pid),"/T","/F"],check=False,
                           stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=10)
        try:
            stdout,stderr=process.communicate(timeout=10)
        except subprocess.TimeoutExpired as cleanup_error:
            stdout=cleanup_error.output or b"";stderr=cleanup_error.stderr or b""
            if process.stdout is not None:process.stdout.close()
            if process.stderr is not None:process.stderr.close()
            (out/(label+".stdout")).write_bytes(stdout)
            (out/(label+".stderr")).write_bytes(stderr)
            save(out/(label+".command.json"),dict(argv=argv,cwd=str(cwd),returncode=process.poll(),
                 watchdog_or_interruption=True,pipe_drain_confirmed=False,cleanup_confirmed=False))
            raise RuntimeError("Owned process/pipe cleanup unconfirmed after bounded wait") from cleanup_error
        (out/(label+".stdout")).write_bytes(stdout)
        (out/(label+".stderr")).write_bytes(stderr)
        save(out/(label+".command.json"),dict(argv=argv,cwd=str(cwd),returncode=process.returncode,
                                             watchdog_or_interruption=True))
        raise
    (out/(label+".stdout")).write_bytes(stdout)
    (out/(label+".stderr")).write_bytes(stderr)
    save(out/(label+".command.json"),dict(argv=argv,cwd=str(cwd),returncode=process.returncode,
                                         watchdog_or_interruption=timed_out))
    return process.returncode,stdout.decode("utf-8",errors="replace"),stderr.decode("utf-8",errors="replace")


def manifest(out):
    save(out/"SHA256.json",{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob("*"))
                           if p.is_file() and p.name!="SHA256.json"})
