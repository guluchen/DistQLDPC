"""Force high coordinates into positive and negative certificates."""
import json
from pathlib import Path
import subprocess
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]


def query(n, side, ones, hx_data, hz_data, expected, binary="pcm-wide", *options):
    with tempfile.TemporaryDirectory() as name:
        hx,hz = Path(name)/"hx",Path(name)/"hz"
        hx.write_text(hx_data)
        hz.write_text(hz_data)
        w = "".join("1" if i in ones else "0" for i in range(n))
        p = subprocess.run([ROOT/binary,str(n),hx,hz,*options],input=f"{side}\n{w}\n",
                           text=True,capture_output=True)
        if expected is None:
            assert p.returncode == 3 and json.loads(p.stdout) == {"status":"UNKNOWN"}, (p.stdout,p.stderr)
        else:
            obj=json.loads(p.stdout)
            assert p.returncode == 0 and obj["status"] == "FOUND" and obj["distance"] == expected
            assert obj[side.lower()] == w


if __name__ == "__main__":
    # Exercise the three Uint63 lanes, including their end coordinates.
    for n in (66, 126, 188, 189):
        active = n - n % 2
        row = "1"*active+"0"*(n-active)+"\n"
        weights = {0, active-1} if n == active else {n-1}
        query(n, "X", weights, row, row, len(weights), "pcm-small", "reverse-bfs", "pair-pack")
        query(n, "X", {0}, row, row, None, "pcm-small", "sparse-checks")
    query(190, "X", {189}, "", "", None, "pcm-small")
    # Any two bits form a minimum logical for this single even stabilizer.
    for n in (190, 252, 378):
        all_ones = "1"*n+"\n"
        query(n,"X",{188,n-1},all_ones,all_ones,2)
        query(n,"Z",{62,189},all_ones,all_ones,2)
        query(n,"X",{189},all_ones,all_ones,None)
    # Two otherwise valid X bits lose to a Z singleton in an asymmetric code.
    query(190,"X",{0,189},"","1"*190+"\n",None)
    query(190,"Z",{189},"","1"*190+"\n",1)
    query(379,"Z",{378},"","",None)
    for n in (380, 504, 756):
        all_ones = "1"*n+"\n"
        query(n,"X",{377,n-1},all_ones,all_ones,2,"pcm-large")
        query(n,"Z",{188,378},all_ones,all_ones,2,"pcm-large")
        query(n,"Z",{378},all_ones,all_ones,None,"pcm-large")
    query(757,"Z",{756},"","",None,"pcm-large")
    # Both halves have a zero column. A valid weight-two proposal loses to
    # the singleton on it, even though every other column has odd degree.
    for n, binary in ((190, "pcm-wide"), (380, "pcm-large")):
        row = "1"*(n-2)+"00\n"
        query(n, "X", {0,1}, row, row, None, binary)
        query(n, "Z", {n-1}, row, row, 1, binary)
    for n, binary in ((190,"pcm-wide"),(380,"pcm-large")):
        even = "1"*n+"\n"
        query(n,"X",{0,n-1},even,even,2,binary,"reverse-bfs")
        missing = "1"*(n-2)+"00\n"
        query(n,"Z",{0,1},missing,missing,None,binary,"reverse-bfs")
    for n,binary in ((190,"pcm-wide"),(380,"pcm-large")):
        row="1"*n+"\n"
        query(n,"Z",{0,n-1},row,row,2,binary,"pair-pack","reverse-bfs")
        query(n,"X",{0},row,row,None,binary,"pair-pack")
    for n,binary in ((192,"pcm-wide"),(382,"pcm-large")):
        # Pair the coordinates of each of three short checks so that the CSS
        # commutation condition holds. These rows produce three new pair sums.
        rows=["".join(bit*2 for bit in row)+"0"*(n-8) for row in ("1101","1110","0110")]
        rows.append("0"*8+"1"*(n-8))
        pcm="\n".join(rows)+"\n"
        query(n,"X",{2,3},pcm,pcm,2,binary,"sparse-checks","reverse-bfs","pair-pack")
        query(n,"X",{2},pcm,pcm,None,binary,"sparse-checks")
    # Asymmetric stabilizers exchanged by an involution. Witness sets for
    # the two orientations differ, so swapping the X/Z result is observable.
    for n,binary in ((66,"pcm-small"),(190,"pcm-wide"),(380,"pcm-large")):
        xrow="11"+"0"*(n-2)+"\n"
        zrow="0"*(n//2)+"11"+"0"*(n-n//2-2)+"\n"
        query(n,"X",{0},xrow,zrow,1,binary)
        query(n,"Z",{n//2},xrow,zrow,1,binary)
        query(n,"X",{n//2},xrow,zrow,None,binary)
        query(n,"Z",{0},xrow,zrow,None,binary)
    # Hypergraph product of two length-seven repetition codes. The seven
    # disjoint rows (columns) in the 7 x 7 data block certify the two halves.
    d=7
    n=d*d+(d-1)*(d-1)
    hxrows=[]; hzrows=[]
    def matrix_text(rows):
        return "".join("".join("1" if i in row else "0" for i in range(n))+"\n" for row in rows)
    for i in range(d-1):
        for j in range(d):
            hx={i*d+j,(i+1)*d+j}
            hz={j*d+i,j*d+i+1}
            for k in (j-1,j):
                if 0<=k<d-1:
                    hx.add(d*d+i*(d-1)+k)
                    hz.add(d*d+k*(d-1)+i)
            hxrows.append(hx);hzrows.append(hz)
    xmat,zmat=matrix_text(hxrows),matrix_text(hzrows)
    xword=set(range(d));zword=set(range(0,d*d,d))
    query(n,"X",xword,xmat,zmat,d,"pcm-small")
    query(n,"Z",zword,xmat,zmat,d,"pcm-small")
    query(n,"X",xword ^ hxrows[-1],xmat,zmat,None,"pcm-small")
    query(n,"X",xword,xmat,zmat,d,"pcm-small","reverse-bfs","erasure-pack")
    query(n,"Z",{0},xmat,zmat,None,"pcm-small","erasure-pack")
    query(n,"Z",zword,xmat,zmat,d,"pcm-small","class-parity","erasure-pack")
    query(n,"X",xword ^ hxrows[-1],xmat,zmat,None,"pcm-small","class-parity")
    # Above the small-kernel cutoff, exercise the complete C upper/Coq lower
    # pipeline and independently check its file-level witness.
    with tempfile.TemporaryDirectory() as td:
        hx, hz = Path(td)/"hx", Path(td)/"hz"
        for n in (66, 190, 380):
            hx.write_text("1"*n+"\n"); hz.write_text(hx.read_text())
            res = subprocess.run([sys.executable,ROOT/"certified.py",str(n),hx,hz],
                                 capture_output=True,text=True,check=True)
            obj=json.loads(res.stdout)
            assert obj["status"] == "FOUND" and obj["distance"] == 2
            x,z = int(obj["x"][::-1],2),int(obj["z"][::-1],2)
            assert x.bit_count()%2 == z.bit_count()%2 == 0 and (x|z).bit_count() == 2
    with tempfile.TemporaryDirectory() as td:
        h=Path(td)/"pcm"; h.write_text("1"*66+"\n")
        for count in ("0","4097","bad"):
            cp=subprocess.run([ROOT/"pcm-upper","66",h,h,count],capture_output=True)
            assert cp.returncode == 2
        found=subprocess.run([sys.executable,ROOT/"certified.py","66",h,h,"--upper-rounds","128",
                              "--row-order","reverse-bfs","--pair-pack"],capture_output=True,text=True,check=True)
        assert json.loads(found.stdout)["distance"] == 2
    print("4 upper-effort controls passed")
    print("66 certificate boundary controls and 3 end-to-end C upper-witness controls passed")
