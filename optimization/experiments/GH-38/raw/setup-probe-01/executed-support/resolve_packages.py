"""Read-only cached-index dependency resolver; never installs or downloads."""
import hashlib,json,re,sys
from pathlib import Path

def resolve(workspace):
    workspace=Path(workspace)
    index=workspace/'E004-windows-runtime/cache/https%3a%2f%2fmirrors.kernel.org%2fsourceware%2fcygwin%2f/x86_64/setup.ini'
    data=index.read_bytes()
    expected=json.loads((Path(__file__).parent/'PACKAGE-METADATA.json').read_text())['setup_ini_sha512']
    assert hashlib.sha512(data).hexdigest()==expected
    blocks={b.splitlines()[0]:b for b in data.decode().split('\n@ ')[1:]}
    installed={}
    db=workspace/'E004-windows-runtime/cygwin/etc/setup/installed.db'
    for line in db.read_text().splitlines()[1:]:
        name,archive,_=line.split()
        installed[name]=re.sub(r'\.tar\.(?:xz|bz2|gz|zst)$','',archive)[len(name)+1:]
    providers={}
    for name,block in blocks.items():
        block=re.split(r'^\[(?:prev|test)\]',block,flags=re.M)[0]
        match=re.search(r'^provides: (.+)$',block,re.M)
        if match:
            for provided in match.group(1).split(','):
                providers.setdefault(provided.strip(),[]).append(name)
    queue=['clang'];rows={};virtual=[]
    while queue:
        name=queue.pop(0)
        if name in rows:continue
        if name not in blocks:
            choices=[p for p in providers.get(name,[]) if p in installed]
            assert len(choices)==1,'Unresolved/ambiguous virtual package '+name
            virtual.append(dict(predicate=name,provider=choices[0],proof='Exact installed provider version verified recursively'))
            queue.append(choices[0]);continue
        block=re.split(r'^\[(?:prev|test)\]',blocks[name],flags=re.M)[0]
        fields={key:re.search(r'^'+key+r': (.+)$',block,re.M).group(1) for key in ['version','install']}
        match=re.search(r'^depends2: (.+)$',block,re.M)
        dependencies=[]
        for item in (match.group(1).split(',') if match else []):
            item=item.strip()
            if item=='_windows ( >= 6.3 )':
                virtual.append(dict(parent=name,predicate=item,proof='Supervisor requires native Windows >=6.3'));continue
            assert re.fullmatch(r'[A-Za-z0-9_+.-]+',item),'Unimplemented dependency constraint: '+item
            dependencies.append(item)
        path,size,digest=fields['install'].split()
        assert path.startswith(('x86_64/release/','noarch/release/')) and '..' not in Path(path).parts,(name,path)
        assert len(digest)==128
        rows[name]=dict(version=fields['version'],archive=path,bytes=int(size),sha512=digest,
                       dependencies=dependencies,installed_version=installed.get(name),
                       action='REUSE_IMMUTABLE' if installed.get(name)==fields['version'] else 'OVERLAY_ONLY')
        if name in installed:assert installed[name]==fields['version'],'Runtime version mismatch: '+name
        queue.extend(dependencies)
    return dict(index_sha512=expected,installed_db_sha256=hashlib.sha256(db.read_bytes()).hexdigest(),
                packages=rows,virtual_dependencies=virtual,
                overlay_archives_bytes=sum(r['bytes'] for r in rows.values() if r['action']=='OVERLAY_ONLY'),
                provenance='Cached retained official-mirror index; archive hashes are pins, not fresh signature verification')

if __name__=='__main__':
    print(json.dumps(resolve(sys.argv[1]),indent=2))
