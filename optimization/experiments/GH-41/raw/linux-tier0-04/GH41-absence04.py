import json,pathlib
remaining=[]
for p in pathlib.Path('/proc').iterdir():
    if p.name.isdigit():
        try:
            raw=(p/'stat').read_text(); fields=raw[raw.rfind(')')+2:].split()
        except (FileNotFoundError,ProcessLookupError):
            continue
        if int(fields[3])==3437395:
            remaining.append(dict(pid=int(p.name),group=int(fields[2]),session=int(fields[3]),birth=int(fields[19])))
print(json.dumps(dict(leader_proc_absent=not pathlib.Path('/proc/3437395').exists(),remaining_session_members=remaining)))
