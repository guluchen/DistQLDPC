"""GH38 attempt02: Clang codegen, original GNU linking; no solver/timing."""
import argparse,ctypes as C,hashlib,importlib.util,json,os,posixpath,re,struct,subprocess,sys,time,traceback
from pathlib import Path
HERE=Path(__file__).resolve().parent;REPO=HERE.parents[2];ROOT=HERE.parents[3]
ASSIGNMENT='HOST_SLOT_NOT_ASSIGNED'
HELPER_SHA='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2'
SUPPORT=['windows_codegen_probe.py','setup_worker.py','resolve_packages.py','windows_cpu_window.py','PACKAGE-CLOSURE.json','PACKAGE-METADATA.json']
def sha(p):
    h=hashlib.sha256()
    with Path(p).open('rb') as f:
        for block in iter(lambda:f.read(1048576),b''):h.update(block)
    return h.hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2),encoding='utf-8',newline='\n')
def cyg(p):
    p=str(p).replace('\\','/')
    return '/cygdrive/'+p[0].lower()+p[2:] if len(p)>2 and p[1:3]==':/' else p
def pe_properties(path):
    data=Path(path).read_bytes();offset=struct.unpack_from('<I',data,0x3c)[0]
    assert data[offset:offset+4]==b'PE\0\0'
    count=struct.unpack_from('<H',data,offset+6)[0];size=struct.unpack_from('<H',data,offset+20)[0]
    optional=offset+24;assert struct.unpack_from('<H',data,optional)[0]==0x20b
    manifest=None
    for index in range(count):
        row=optional+size+index*40
        if data[row:row+8].rstrip(b'\0')!=b'.rsrc':continue
        length,start=struct.unpack_from('<II',data,row+16);section=data[start:start+length]
        begin=section.find(b'<?xml');end=section.find(b'</assembly>',begin)
        if begin>=0 and end>begin:manifest=section[begin:end+len(b'</assembly>')]
    assert manifest is not None,'Original GNU default manifest missing'
    return dict(machine=struct.unpack_from('<H',data,offset+4)[0],
        dll_characteristics=struct.unpack_from('<H',data,optional+70)[0],
        subsystem=struct.unpack_from('<H',data,optional+68)[0],
        manifest_sha256=hashlib.sha256(manifest).hexdigest(),manifest_xml=manifest.decode())
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--assignment',required=True);ap.add_argument('--support-sha',required=True);a=ap.parse_args()
    assert os.name=='nt' and sys.getwindowsversion()[:2]>=(6,3)
    assert ASSIGNMENT!='HOST_SLOT_NOT_ASSIGNED' and a.assignment==ASSIGNMENT,'Named setup/probe assignment not frozen'
    assert REPO.name=='GH38-CLANG'
    git=lambda *v:subprocess.check_output(['git','-C',str(REPO),*v],timeout=20)
    assert git('rev-parse','HEAD').decode().strip()==a.support_sha
    pins={}
    for name in SUPPORT:
        p=HERE/name;committed=git('show',a.support_sha+':optimization/experiments/GH-38/'+name)
        assert p.read_bytes().replace(b'\r\n',b'\n')==committed.replace(b'\r\n',b'\n'),name
        pins[name]=sha(p)
    assert pins['windows_cpu_window.py']==HELPER_SHA
    assert git('rev-parse',a.support_sha+':src')==git('rev-parse','24572d6d09cce9a4a5faa58300a89e0feba9da6a:src')
    out=a.out.resolve();assert out.parent==ROOT and out.name=='GH38-setup-probe-02'
    out.mkdir(exist_ok=False);save(out/'support-before.json',dict(head=a.support_sha,assignment=a.assignment,hashes=pins))
    def load(name,file):
        spec=importlib.util.spec_from_file_location(name,HERE/file);mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod
    m=load('gh38window','windows_cpu_window.py');resolver=load('gh38resolver','resolve_packages.py')
    closure=resolver.resolve(ROOT)
    assert closure==json.loads((HERE/'PACKAGE-CLOSURE.json').read_text(encoding='utf-8-sig'))
    save(out/'closure.json',closure)
    runtime=ROOT/'E004-windows-runtime/cygwin';previous=ROOT/'GH38-setup-probe-01';overlay=previous/'overlay';worker=HERE/'setup_worker.py'
    prior_record=HERE/'raw/setup-probe-01'
    prior_index=git('show','cee5df628ec9a37f7626dacf79e3d8a96b43f89d:optimization/experiments/GH-38/raw/setup-probe-01/PUBLIC-SHA256.json')
    assert (prior_record/'PUBLIC-SHA256.json').read_bytes()==prior_index,'Prior evidence catalog changed'
    catalog=json.loads(prior_index)
    for name,expected in catalog['files'].items():
        assert sha(prior_record/name)==expected,name
        if (previous/name).is_file():assert sha(previous/name)==expected,name
    manifest=prior_record/'runtime-before.json'
    makefile=REPO/'Makefile';committed=git('show',a.support_sha+':Makefile')
    assert makefile.read_bytes().replace(b'\r\n',b'\n')==committed.replace(b'\r\n',b'\n')
    make_before=sha(makefile)
    save(out/'prior-evidence.json',dict(public_commit='cee5df628ec9a37f7626dacf79e3d8a96b43f89d',catalog_sha256=sha(prior_record/'PUBLIC-SHA256.json'),files_verified=len(catalog['files']),production_makefile_sha256=make_before))
    assert (runtime/'etc/setup/installed.db').read_bytes()==(ROOT/'DistQLDPC/optimization/experiments/E004/raw/windows-setup-2026-10-08/installed.db').read_bytes()
    window=None;current=None;rows=[];commands=[];sequence=0;started=time.monotonic();snapshotted=False
    summary=dict(status='INCONCLUSIVE',engineering='NOT_ESTABLISHED',science='NOT_RUN',performance='NOT_MEASURED',support=a.support_sha,assignment=a.assignment)
    k=m.k;k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)];k.QueryInformationJobObject.restype=C.c_int
    def owned():
        buf=C.create_string_buffer(65536);used=C.c_ulong()
        if not k.QueryInformationJobObject(window.job,3,buf,len(buf),C.byref(used)):raise C.WinError(C.get_last_error())
        total,count=struct.unpack_from('<II',buf);assert total==count and 8+8*count<=len(buf)
        return [p for p in struct.unpack_from('<'+'Q'*count,buf,8) if p!=os.getpid()]
    def observe(label):
        row=window.observe(label);rows.append(row);save(out/'resources.json',rows);assert row['eligible'],'Spare resource guard '+label
    def cleanup():
        actions=[]
        for pid in owned():
            if pid not in owned():continue
            r=subprocess.run(['taskkill','/PID',str(pid),'/T','/F'],capture_output=True,text=True,timeout=10)
            actions.append(dict(pid=pid,rc=r.returncode,stdout=r.stdout,stderr=r.stderr))
        if current is not None and current.poll() is None:current.wait(timeout=10)
        end=time.monotonic()+5
        while owned() and time.monotonic()<end:time.sleep(.1)
        rest=owned();save(out/('cleanup-'+str(sequence)+'.json'),dict(actions=actions,remaining=rest));assert not rest,'Owned cleanup incomplete'
    def modules(pid):
        ps=C.WinDLL('psapi',use_last_error=True)
        # Explicit HANDLE/BOOL/DWORD prototypes; no dependence on the earlier
        # descendant-affinity call having initialized OpenProcess's signature.
        k.OpenProcess.argtypes=[C.c_ulong,C.c_int,C.c_ulong]
        k.OpenProcess.restype=C.c_void_p
        ps.EnumProcessModulesEx.argtypes=[C.c_void_p,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong),C.c_ulong]
        ps.EnumProcessModulesEx.restype=C.c_int
        ps.GetModuleFileNameExW.argtypes=[C.c_void_p,C.c_void_p,C.c_wchar_p,C.c_ulong]
        ps.GetModuleFileNameExW.restype=C.c_ulong
        handle=k.OpenProcess(0x410,False,pid)
        assert handle,'Cannot inspect live linkage'
        try:
            array=(C.c_void_p*4096)();needed=C.c_ulong()
            assert ps.EnumProcessModulesEx(handle,array,C.sizeof(array),C.byref(needed),3) and needed.value<=C.sizeof(array)
            assert needed.value>0 and needed.value%C.sizeof(C.c_void_p)==0
            result=[]
            for module in array[:needed.value//C.sizeof(C.c_void_p)]:
                name=C.create_unicode_buffer(32768)
                length=ps.GetModuleFileNameExW(handle,module,name,len(name))
                assert 0<length<len(name),'Missing/truncated loaded-module path'
                p=Path(name.value).resolve();item=dict(path=str(p))
                if p.is_relative_to(overlay) or p.is_relative_to(runtime):item['sha256']=sha(p)
                result.append(item)
            return result
        finally:k.CloseHandle(handle)
    def run(label,argv,limit=60,final=False):
        nonlocal sequence,current
        sequence+=1
        if not final:assert time.monotonic()-started<600,'Whole setup deadline'
        window.previous=m.ticks();time.sleep(2.1);observe(label+'-preflight')
        command=dict(label=label,argv=list(map(str,argv)),limit_sec=limit)
        env=dict(os.environ,PATH=str(overlay/'bin')+os.pathsep+str(runtime/'bin')+os.pathsep+os.environ['PATH'],LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
        begin=time.monotonic();last=begin
        with (out/(label+'.stdout')).open('wb') as stdout,(out/(label+'.stderr')).open('wb') as stderr:
            try:
                current=subprocess.Popen(command['argv'],cwd=out,env=env,stdout=stdout,stderr=stderr)
                while current.poll() is None:
                    time.sleep(.05);now=time.monotonic()
                    if now-last>=2:
                        children=m.descendant_affinities(current.pid)
                        assert all(r['mask']==window.mask and r['priority_class']==0x8000 for r in children)
                        command.setdefault('descendants',[]).append(children);observe(label);last=now
                        if label.endswith('-execution') and 'loaded_modules' not in command:command['loaded_modules']=modules(current.pid)
                    if now-begin>limit or (not final and now-started>600):raise subprocess.TimeoutExpired(argv,limit)
                command['rc']=current.returncode;assert not owned(),'Orphan after command';assert current.returncode==0,'Engineering command failure '+label
            except BaseException as e:command['error']=repr(e);cleanup();raise
            finally:commands.append(command);save(out/'commands.json',commands)
        print(label+' complete',flush=True)
        return (out/(label+'.stdout')).read_text(errors='replace'),(out/(label+'.stderr')).read_text(errors='replace')
    def task(label,action,extra=(),limit=300,final=False):
        return run(label,[sys.executable,worker,action,'--runtime',runtime,'--result',out/(label+'.json'),*extra],limit,final)
    try:
        assert not any(os.environ.get(v) for v in ['CXX','CXXFLAGS','LDFLAGS','MAKEFLAGS','CPATH','CPLUS_INCLUDE_PATH','LIBRARY_PATH','GCC_EXEC_PREFIX'])
        window=m.Window(True,0x8000);save(out/'window.json',window.selection)
        task('overlay-reuse-before','verify-closure',['--overlay',overlay,'--manifest',manifest,'--closure',HERE/'PACKAGE-CLOSURE.json','--cache',previous/'archives']);snapshotted=True
        empty=out/'empty.cc';empty.write_text('\n',encoding='ascii')
        probe=out/'linkage.cc';probe.write_text('#include <cstdio>\n#include <vector>\n#include <string>\n#include <zlib.h>\n#include <unistd.h>\nint main(int argc,char**){std::vector<int> v(argc+4,argc+7);std::string s(v.size(),char(v[1]));printf("%ld %zu %zu %zu %zu %zu %d %d %s\\n",(long)__cplusplus,sizeof(void*),sizeof(int),sizeof(bool),sizeof(v),sizeof(s),_GLIBCXX_USE_CXX11_ABI,(int)s[1],zlibVersion());fflush(stdout);sleep(5);return 0;}\n',encoding='ascii')
        results={};flags=['-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
        for name,exe in [('gcc','g++.exe'),('clang','clang++.exe')]:
            compiler=overlay/'bin'/exe;assert compiler.is_file(),str(compiler);results[name]={}
            common=flags+(['-Wno-reserved-user-defined-literal'] if name=='clang' else [])
            for label,args in [('version',['--version']),('target',['-dumpmachine']),('macros',['-dM','-E','-x','c++',cyg(probe)]),('includes',['-v','-E','-x','c++',cyg(probe)]),('compile-driver',[*common,'-###','-c',cyg(probe),'-o',cyg(out/(name+'-probe.o'))])]:
                results[name][label]=run(name+'-'+label,[compiler,*args])
            run(name+'-compile',[compiler,*common,'-c',cyg(probe),'-o',cyg(out/(name+'-probe.o'))])
            run(name+'-gnu-link-driver',[overlay/'bin/g++.exe',*flags,'-###',cyg(out/(name+'-probe.o')),'-lz','-o',cyg(out/(name+'-probe.exe'))])
            run(name+'-link',[overlay/'bin/g++.exe',*flags,cyg(out/(name+'-probe.o')),'-Wl,-t','-lz','-o',cyg(out/(name+'-probe.exe'))])
            results[name]['execution']=run(name+'-execution',[out/(name+'-probe.exe')])
        assert '14.4.0' in results['gcc']['version'][0] and '22.1.8' in results['clang']['version'][0]
        assert results['gcc']['execution'][0]==results['clang']['execution'][0],'Minimal ABI/library output differs'
        features=['__cplusplus','__SSE__','__SSE2__','__AVX__','__AVX2__','__AVX512F__','__FMA__','__BMI__','__BMI2__','__x86_64__','__CYGWIN__','__SIZEOF_POINTER__','__SIZEOF_LONG__','__SIZEOF_INT__','__MMX__','__SSE3__','__SSSE3__','__SSE4_1__','__SSE4_2__','__EXCEPTIONS','__GXX_RTTI','__GLIBCXX__','_GLIBCXX_USE_CXX11_ABI']
        def macros(text):return dict(re.findall(r'^#define (\S+) (.*)$',text,re.M))
        definitions={n:macros(r['macros'][0]) for n,r in results.items()}
        for feature in features:assert definitions['gcc'].get(feature)==definitions['clang'].get(feature),'Target/language feature differs '+feature
        original=json.loads(manifest.read_text())
        physical=lambda p:posixpath.normpath(p).replace('/usr/lib/','/lib/',1).replace('/usr/bin/','/bin/',1).lstrip('/')
        traces={};headers={};pe={}
        for name in ['gcc','clang']:
            traces[name]=[]
            for path in (out/(name+'-link.stdout')).read_text().splitlines():
                if path==cyg(out/(name+'-probe.o')):continue
                assert path.startswith('/usr/'),'Unexpected GNU link trace '+path
                rel=physical(path);assert original.get(rel)==sha(overlay/rel),'Unmatched GNU linked input '+rel
                traces[name].append(dict(relative=rel,sha256=original[rel]))
            assert traces[name],'Missing GNU link trace'
            headers[name]=[]
            for path in sorted(set(re.findall(r'^#\s+\d+\s+"([^\"]+)"',(out/(name+'-includes.stdout')).read_text(),re.M))):
                if not path.startswith('/usr/'):continue
                rel=physical(path);digest=sha(overlay/rel);resource=rel.startswith('lib/clang/22/include/')
                assert resource or original.get(rel)==digest,'Changed GNU header '+rel
                headers[name].append(dict(relative=rel,sha256=digest,compiler_resource=resource))
            pe[name]=pe_properties(out/(name+'-probe.exe'))
        assert traces['gcc']==traces['clang'],'Original GNU link recipes differ'
        assert pe['gcc']==pe['clang'],'Effective manifest/security/PE properties differ'
        for rel in ['bin/g++.exe','bin/ld.exe','lib/gcc/x86_64-pc-cygwin/14/collect2.exe']:
            assert original.get(rel)==sha(overlay/rel),'GNU driver/linker differs '+rel
        save(out/'gnu-comparability.json',dict(linked_inputs=traces,headers=headers,pe=pe,
            original_gnu_driver_linker_identical=True,original_manifest_and_security_identical=True))
        for command in commands:
            if not command['label'].endswith('-execution'):continue
            live=command.get('loaded_modules');assert live,'No actual live linkage evidence'
            dlls=[row for row in live if Path(row['path']).name.lower().startswith('cyg')]
            assert any(Path(row['path']).name.lower()=='cygwin1.dll' for row in dlls)
            for row in dlls:
                path=Path(row['path']);assert path.is_relative_to(overlay),'Unexpected runtime root'
                rel=path.relative_to(overlay).as_posix();assert original.get(rel)==row.get('sha256'),'New/replaced scientific DLL '+rel
        summary['engineering']='CODEGEN_ONLY_MINIMAL_GNU_LINK_HEADER_ABI_ISA_PE_DLL_GATES_PASS / INDEPENDENT_REVIEW_REQUIRED'
        save(out/'probe-results.json',results)
        # Explicit human/source audit of retained driver, header and linker trace
        # remains required. No solver build or scientific Tier0 implied.
    except BaseException:summary['error']=traceback.format_exc();print(summary['error'],flush=True)
    finally:
        if window is not None:
            try:
                cleanup()
                if snapshotted:task('overlay-reuse-after','verify-closure',['--overlay',overlay,'--manifest',manifest,'--closure',HERE/'PACKAGE-CLOSURE.json','--cache',previous/'archives'],300,True)
                assert all(sha(HERE/n)==h for n,h in pins.items()),'Support changed'
                assert sha(makefile)==make_before,'Production Makefile changed'
                summary['remaining_owned']=owned()
            except BaseException:summary['cleanup_or_identity_error']=traceback.format_exc()
            finally:
                summary['restoration']=window.close()
                if not all(summary['restoration'].get(f) is True for f in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']):summary['cleanup_or_identity_error']='Restoration incomplete'
        save(out/'summary.json',summary)
    return 1 if summary.get('error') or summary.get('cleanup_or_identity_error') else 0
if __name__=='__main__':raise SystemExit(main())
