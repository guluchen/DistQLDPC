"""Decode lossless Actions evidence without trusting path names or truncation."""
import base64,gzip,hashlib,json,re,sys
from pathlib import Path
log=Path(sys.argv[1]).read_text()
hashes=re.findall(r'GH209_EVIDENCE_PAYLOAD_SHA256=([0-9a-f]{64})',log)
lengths=re.findall(r'GH209_EVIDENCE_PAYLOAD_BYTES=(\d+)',log)
parts=re.findall(r'GH209_EVIDENCE_GZIP_B64=(\d+)/(\d+):([A-Za-z0-9+/=]+)',log)
assert len(hashes)==len(lengths)==1 and parts,'missing payload metadata/chunks'
counts={int(total) for _,total,_ in parts};assert len(counts)==1
count=counts.pop();chunks={int(i):data for i,_,data in parts}
assert len(chunks)==len(parts)==count and set(chunks)==set(range(1,count+1)),'duplicate/truncated/out-of-order index set'
payload=gzip.decompress(base64.b64decode(''.join(chunks[i] for i in range(1,count+1)),validate=True))
assert len(payload)==int(lengths[0]),'payload length mismatch'
assert hashlib.sha256(payload).hexdigest()==hashes[0],'payload SHA mismatch'
evidence=json.loads(payload)
Path(sys.argv[2]).write_text(json.dumps(evidence))
print(json.dumps(dict(chunks=count,payload_bytes=len(payload),payload_sha256=hashes[0],
                     files={k:len(v) for k,v in evidence.items() if isinstance(v,dict)})))
