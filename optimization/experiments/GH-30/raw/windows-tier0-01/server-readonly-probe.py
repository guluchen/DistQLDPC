# Read-only resource snapshot; no benchmark, reservation or process mutation.
import json,time
def read():
    rows={}
    with open('/proc/stat') as f:
        for line in f:
            parts=line.split()
            if parts and parts[0] in ('cpu','cpu102','cpu230'):
                # guest counters are already included in user/nice.
                values=list(map(int,parts[1:9]))
                rows[parts[0]]=(sum(values),values[3]+values[4])
    return rows
rows=[];previous=read()
for i in range(3):
    time.sleep(1);current=read();spare={}
    for k in previous:
        dt=current[k][0]-previous[k][0];idle=current[k][1]-previous[k][1]
        spare[k]=100*idle/dt if dt else None
    rows.append({'utc':time.time(),'idle_percent':spare});previous=current
print(json.dumps({'read_only':True,'windows':rows,'policy':'no jobs unless global spare>50%; fixed pair separate eligibility'},indent=2))
