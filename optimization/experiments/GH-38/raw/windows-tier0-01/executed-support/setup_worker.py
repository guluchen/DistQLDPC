"""Bounded-supervisor child only: overlay file operations and pinned downloads.
No installer, registry edit, postinstall script, solver or benchmark execution.
"""
import argparse,hashlib,json,os,shutil,stat,tarfile,urllib.request
from pathlib import Path,PurePosixPath

def digest(p,algorithm='sha256'):
    h=hashlib.new(algorithm)
    with Path(p).open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()

def write(p,value):
    Path(p).write_text(json.dumps(value,indent=2),encoding='utf-8',newline='\n')

def snapshot(root):
    root=Path(root).resolve();result={}
    for parent,dirs,files in os.walk(root,followlinks=False):
        for name in dirs+files:
            p=Path(parent)/name
            assert not p.is_symlink() and not (p.stat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT),str(p)
        for name in files:
            p=Path(parent)/name;result[p.relative_to(root).as_posix()]=digest(p)
    assert result,'Empty runtime tree'
    return result

def destination(root,name):
    # Cygwin default logical mounts map /usr/bin and /usr/lib to physical
    # prefix/bin and prefix/lib. Other paths remain beneath the fresh prefix.
    p=PurePosixPath(name)
    assert not p.is_absolute() and '..' not in p.parts and '\\' not in name and ':' not in name,name
    parts=list(p.parts)
    if parts[:2] in [['usr','bin'],['usr','lib']]:parts=parts[1:]
    assert parts,name
    target=root.joinpath(*parts).resolve()
    assert target.is_relative_to(root),name
    return target

def extract(archive,root):
    root=Path(root).resolve();links=[];records=[];total=0
    with tarfile.open(archive,'r:*') as tf:
        for m in tf:
            assert len(records)<150000,'Member-count limit'
            target=destination(root,m.name)
            assert not m.isdev() and not m.isfifo(),'Unsupported member '+m.name
            if m.isdir():target.mkdir(parents=True,exist_ok=True)
            elif m.isfile():
                total+=m.size;assert m.size<=256*1024*1024 and total<=2*1024**3,'Expansion limit'
                target.parent.mkdir(parents=True,exist_ok=True)
                with tf.extractfile(m) as src:
                    data=src.read(m.size+1)
                assert len(data)==m.size,m.name
                if target.exists():assert target.is_file() and target.read_bytes()==data,'Original/package collision '+m.name
                else:target.write_bytes(data)
            elif m.issym() or m.islnk():links.append(m)
            else:raise AssertionError('Unsupported archive member '+m.name)
            records.append(dict(name=m.name,type=m.type.decode('ascii'),bytes=m.size,link=m.linkname))
        # Materialize aliases as byte-identical regular copies, never OS links.
        # Preserve the alias spelling so clang++ retains C++ driver selection.
        pending=list(links)
        while pending:
            remaining=[];progress=False
            for m in pending:
                target=destination(root,m.name)
                raw=m.linkname
                assert '\\' not in raw and ':' not in raw,raw
                logical=PurePosixPath(raw.lstrip('/')) if raw.startswith('/') or m.islnk() else PurePosixPath(m.name).parent/PurePosixPath(raw)
                normalized=[]
                for item in logical.parts:
                    if item=='..':assert normalized,raw;normalized.pop()
                    elif item!='.':normalized.append(item)
                source=destination(root,'/'.join(normalized))
                if not source.is_file():remaining.append(m);continue
                assert not source.is_symlink(),str(source)
                target.parent.mkdir(parents=True,exist_ok=True)
                if target.exists():assert digest(target)==digest(source),'Alias collision '+m.name
                else:shutil.copyfile(source,target)
                progress=True
            assert progress or not remaining,'Unresolved/directory alias: '+repr([m.name for m in remaining])
            pending=remaining
    return dict(members=records,expanded_bytes=total,postinstall_executed=False,
                alias_policy='Contained regular-file aliases copied byte identically; unresolved/directory aliases stop')

def verify_closure(runtime,overlay,manifest,closure,cache):
    expected=json.loads(Path(manifest).read_text());original=dict(expected)
    assert snapshot(runtime)==original,'Original runtime changed'
    aliases=[];packages=json.loads(Path(closure).read_text(encoding='utf-8-sig'))['packages']
    for name,row in packages.items():
        if row['action']!='OVERLAY_ONLY':continue
        archive=Path(cache)/Path(row['archive']).name
        assert archive.stat().st_size==row['bytes'] and digest(archive,'sha512')==row['sha512'],name
        total=0;count=0
        with tarfile.open(archive,'r:*') as tf:
            for m in tf:
                count+=1;assert count<=150000,name
                rel=destination(Path(overlay).resolve(),m.name).relative_to(Path(overlay).resolve()).as_posix()
                if m.isdir():continue
                if m.isfile():
                    total+=m.size;assert m.size<=256*1024**2 and total<=2*1024**3,name
                    with tf.extractfile(m) as src:data=src.read(m.size+1)
                    assert len(data)==m.size,m.name
                    h=hashlib.sha256(data).hexdigest()
                    if rel in expected:assert expected[rel]==h,'Package collision '+rel
                    expected[rel]=h
                elif m.issym() or m.islnk():aliases.append((m,rel))
                else:raise AssertionError('Unsupported member '+m.name)
    while aliases:
        remaining=[];progress=False
        for m,rel in aliases:
            raw=m.linkname;assert '\\' not in raw and ':' not in raw,raw
            logical=PurePosixPath(raw.lstrip('/')) if raw.startswith('/') or m.islnk() else PurePosixPath(m.name).parent/PurePosixPath(raw)
            normalized=[]
            for part in logical.parts:
                if part=='..':assert normalized,raw;normalized.pop()
                elif part!='.':normalized.append(part)
            target=destination(Path(overlay).resolve(),'/'.join(normalized)).relative_to(Path(overlay).resolve()).as_posix()
            if target not in expected:remaining.append((m,rel));continue
            if rel in expected:assert expected[rel]==expected[target],rel
            expected[rel]=expected[target];progress=True
        assert progress or not remaining,'Unresolved/directory alias'
        aliases=remaining
    actual=snapshot(overlay)
    assert actual==expected,'Overlay missing/modified/unexpected regular files'
    return dict(original_unchanged=True,original_files=len(original),overlay_files=len(expected),
                original_subset_identical=True,all_added_files_pinned_to_previous_archives=True,
                overlay_sha256=expected,downloads=False,reclone=False)

def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['snapshot','clone','archive','verify','verify-closure'])
    p.add_argument('--runtime',type=Path);p.add_argument('--overlay',type=Path)
    p.add_argument('--manifest',type=Path);p.add_argument('--package',type=Path);p.add_argument('--cache',type=Path)
    p.add_argument('--closure',type=Path)
    p.add_argument('--result',type=Path,required=True);a=p.parse_args()
    if a.action=='snapshot':write(a.result,snapshot(a.runtime))
    elif a.action=='clone':
        assert not a.overlay.exists();a.overlay.mkdir()
        manifest=json.loads(a.manifest.read_text())
        for rel,expected in manifest.items():
            src=a.runtime/rel;assert digest(src)==expected,rel
            dst=destination(a.overlay.resolve(),rel);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
            assert digest(dst)==expected,rel
        write(a.result,dict(files=len(manifest),status='BYTE_IDENTICAL_ORIGINAL_SUBSET'))
    elif a.action=='archive':
        row=json.loads(a.package.read_text());rel=row['archive']
        assert rel.startswith(('x86_64/release/','noarch/release/')) and '..' not in PurePosixPath(rel).parts
        a.cache.mkdir(exist_ok=True);archive=a.cache/Path(rel).name
        assert not archive.exists(),'Fresh cache required'
        request=urllib.request.Request('https://mirrors.kernel.org/sourceware/cygwin/'+rel)
        with urllib.request.urlopen(request,timeout=20) as response,archive.open('xb') as dst:
            assert response.geturl().startswith('https://mirrors.kernel.org/'), 'Unexpected redirect'
            count=0
            for data in iter(lambda:response.read(1024*1024),b''):
                count+=len(data);assert count<=row['bytes'],'Oversized archive';dst.write(data)
        assert count==row['bytes'] and digest(archive,'sha512')==row['sha512'],'Archive pin mismatch'
        result=extract(archive,a.overlay)
        result.update(package=row,archive_sha512=digest(archive,'sha512'),download_bytes=count)
        write(a.result,result)
    elif a.action=='verify-closure':write(a.result,verify_closure(a.runtime,a.overlay,a.manifest,a.closure,a.cache))
    elif a.action=='verify':
        expected=json.loads(a.manifest.read_text());actual=snapshot(a.runtime)
        assert actual==expected,'Original runtime changed'
        if a.overlay:
            for rel,h in expected.items():assert digest(destination(a.overlay.resolve(),rel))==h,'Overlay altered original '+rel
        write(a.result,dict(original_files=len(expected),original_unchanged=True,overlay_original_subset_identical=bool(a.overlay)))

if __name__=='__main__':main()
