"""Strict original-GNU objdump function bytes+relocations; no solver execution."""
import hashlib
import re
SYMBOL="_ZN7Minisat6Solver14propagateForLKEv"

def parse(text):
    lines=text.splitlines();headers=[]
    for i,line in enumerate(lines):
        match=re.fullmatch(r"([0-9a-fA-F]+) <([^>]+)>:",line.strip())
        if match and match[2]==SYMBOL:headers.append((i,int(match[1],16)))
    if len(headers)!=1:raise ValueError("Expected exactly one ForLK function label")
    index,base=headers[0];data=bytearray();relocations=[];instructions=[]
    for line in lines[index+1:]:
        if re.fullmatch(r"[0-9a-fA-F]+ <[^>]+>:",line.strip()):break
        match=re.match(r"^\s*([0-9a-fA-F]+):\s+((?:[0-9a-fA-F]{2}(?:\s+|$))+)(.*)$",line)
        if match:
            address=int(match[1],16);chunk=bytes.fromhex(match[2])
            if address!=base+len(data):raise ValueError("Non-contiguous/omitted function bytes")
            data.extend(chunk);instructions.append(dict(offset=address-base,bytes=chunk.hex(),assembly=match[3].strip()))
            continue
        reloc=re.match(r"^\s*([0-9a-fA-F]+):\s+((?:R_|IMAGE_REL_)[A-Za-z0-9_]+)\s+(.+?)\s*$",line)
        if reloc:
            relocations.append(dict(offset=int(reloc[1],16)-base,kind=reloc[2],target_addend=reloc[3]));continue
        if re.match(r"^\s*[0-9a-fA-F]+:",line) or line.strip()=="...":
            raise ValueError("Unparsed objdump byte/relocation line")
    if not data or len(instructions)<10:raise ValueError("Incomplete/noncredible ForLK function")
    if any(r["offset"]<0 or r["offset"]>=len(data) for r in relocations):raise ValueError("Relocation outside function")
    return dict(symbol=SYMBOL,base=base,bytes=data.hex(),sha256=hashlib.sha256(data).hexdigest(),size=len(data),relocations=relocations,instructions=instructions)

def compare(baseline,candidate):
    equal=baseline["bytes"]==candidate["bytes"] and baseline["relocations"]==candidate["relocations"]
    return dict(status="EXACT_FUNCTION_CODE_IDENTICAL" if equal else "DIFFERENT_INDEPENDENT_REVIEW_REQUIRED",
                exact_bytes_equal=baseline["bytes"]==candidate["bytes"],relative_relocations_equal=baseline["relocations"]==candidate["relocations"],
                baseline=baseline,candidate=candidate,scientific_certification="NOT_ESTABLISHED",performance="NOT_MEASURED",automatic_solver_or_timing=False)
