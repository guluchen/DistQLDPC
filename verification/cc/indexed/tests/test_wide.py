"""Force high coordinates into positive and negative certificates."""
import json
from pathlib import Path
import subprocess
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]


def query(n, side, ones, hx_data, hz_data, expected, binary="pcm-wide"):
    with tempfile.TemporaryDirectory() as name:
        hx,hz = Path(name)/"hx",Path(name)/"hz"
        hx.write_text(hx_data)
        hz.write_text(hz_data)
        w = "".join("1" if i in ones else "0" for i in range(n))
        p = subprocess.run([ROOT/binary,str(n),hx,hz],input=f"{side}\n{w}\n",
                           text=True,capture_output=True)
        if expected is None:
            assert p.returncode == 3 and json.loads(p.stdout) == {"status":"UNKNOWN"}, (p.stdout,p.stderr)
        else:
            obj=json.loads(p.stdout)
            assert p.returncode == 0 and obj["status"] == "FOUND" and obj["distance"] == expected
            assert obj[side.lower()] == w


if __name__ == "__main__":
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
    print("26 certificate boundary controls and 3 end-to-end C upper-witness controls passed")
