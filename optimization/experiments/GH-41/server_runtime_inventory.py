"""Linux read-only runtime inventory. No compiler build, solver, or CPU experiment."""
import argparse,hashlib,json,os,re,shutil,subprocess,sys,sysconfig
from pathlib import Path
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--metadata-only',action='store_true',required=True);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    assert os.name=='posix' and args.metadata_only
    assert os.environ.get('PYTHONDONTWRITEBYTECODE')=='1' and sys.dont_write_bytecode,'Explicit read-only bytecode cache policy required'
    out=args.out.resolve();assert not out.exists(),'Fresh metadata file'
    commands=[];files={};critical_files={};extensions=[]
    def query(argv):
        result=subprocess.run(argv,capture_output=True,timeout=15,env=dict(os.environ,PATH='/usr/bin:/bin',LC_ALL='C'))
        commands.append(dict(argv=argv,returncode=result.returncode,stdout_hex=result.stdout.hex(),stderr_hex=result.stderr.hex()))
        assert result.returncode==0,'Runtime metadata command failed'
        return result.stdout.decode().strip()
    def pin(path,critical=True):
        p=Path(path);assert p.is_absolute() and p.is_file(),str(p)
        for q in [p,p.resolve()]:
            value=hashlib.sha256(q.read_bytes()).hexdigest();files[str(q)]=value
            if critical:critical_files[str(q)]=value
        return str(p.resolve())
    compiler=pin('/usr/bin/g++');version=query([compiler,'-dumpfullversion','-dumpversion'])
    assert version.split('.')[0]=='13','Original GCC13 required'
    target=query([compiler,'-dumpmachine'])
    assert sys.version_info>=(3,11),'process_group=0 requires Python3.11 or newer'
    stdlib=Path(sysconfig.get_path('stdlib')).resolve();assert stdlib.is_dir()
    for path in sorted(stdlib.rglob('*')):
        if 'site-packages' in path.parts or 'dist-packages' in path.parts:continue
        if path.is_file() and path.suffix in ('.py','.so','.pyc'):
            resolved=pin(path,critical=(path.suffix=='.so'))
            if path.suffix=='.so':extensions.append(resolved)
    programs=[compiler,pin('/usr/bin/make'),pin('/usr/bin/bash'),pin('/usr/bin/taskset'),pin('/usr/bin/ldd'),pin(sys.executable)]
    for name in ['cc1plus','collect2','as','ld']:
        result=query([compiler,'-print-prog-name='+name]);path=result if '/' in result else shutil.which(result,path='/usr/bin:/bin')
        programs.append(pin(path))
    zlib=query([compiler,'-print-file-name=libz.so']);assert '/' in zlib,'Native zlib development library unresolved';programs.append(pin(zlib))
    compiler_headers=Path(query([compiler,'-print-file-name=include']));assert compiler_headers.is_absolute()
    for directory in [Path('/usr/include'),compiler_headers]:
        assert directory.is_dir()
        for header in sorted(directory.rglob('*')):
            if header.is_file():pin(header,critical=False)
    for executable in sorted(set(programs+extensions)):
        if executable.endswith('ldd'):continue # shell script itself is pinned, bash is inventoried
        output=query(['/usr/bin/ldd',executable])
        for line in output.splitlines():
            m=re.search(r'=>\s+(/\S+)',line) or re.match(r'\s*(/\S+)',line)
            if m:pin(m.group(1))
    info=dict(schema_version=2,cache_policy='DONTWRITE_BYTECODE_FULL_PRE_POST_EXISTING_PYC',identity_policy='FULL_PRE_IMPORT_AND_POST_RUN_CRITICAL_PER_COMMAND',metadata_only=True,compiler=compiler,gcc_version=version,target=target,python=str(Path(sys.executable).resolve()),
        python_version=sys.version,stdlib=str(stdlib),make=str(Path('/usr/bin/make').resolve()),files=files,critical_files=critical_files,commands=commands,build='NOT_RUN',solver='NOT_RUN')
    out.write_text(json.dumps(info,indent=2)+'\n');print(json.dumps(dict(path=str(out),sha256=hashlib.sha256(out.read_bytes()).hexdigest(),files=len(files))))
if __name__=='__main__':main()
