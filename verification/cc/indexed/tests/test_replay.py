"""Check both Pauli directions and adversarial upper witnesses at the file boundary."""
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def rows(path, words, n):
    path.write_text("".join("".join(str(w >> q & 1) for q in range(n))+"\n" for w in words))


def span(gens):
    result = {0}
    for g in gens:
        result |= {v ^ g for v in result}
    return result


def test_all():
    rng = random.Random(1095)
    count = 0
    with tempfile.TemporaryDirectory() as name:
        hx, hz = Path(name)/"X", Path(name)/"Z"

        def check(n, side, word, budget=1000000):
            bits = "".join(str(word >> i & 1) for i in range(n))
            res = subprocess.run([ROOT/"pcm-check", str(n), hx, hz, str(budget), "39"],
                                 input=f"{side}\n{bits}\n",capture_output=True,text=True)
            assert res.returncode in (0,3), (res.returncode,res.stderr)
            return json.loads(res.stdout)

        for i in range(45):
            n = rng.randint(2,7)
            a = [rng.randrange(1 << n) for _ in range(rng.randint(0,n))]
            orthogonal = [w for w in range(1 << n) if all((w&r).bit_count()%2 == 0 for r in a)]
            b = [rng.choice(orthogonal) for _ in range(rng.randint(0,n))]
            rows(hx,a,n)
            rows(hz,b,n)
            directions = {"X": (b,span(a)), "Z": (a,span(b))}
            valid = [(s,w) for s,(opposite,same) in directions.items() for w in range(1,1<<n)
                     if w not in same and all((w&r).bit_count()%2 == 0 for r in opposite)]
            d = min((w.bit_count() for _,w in valid), default=None)
            got = subprocess.run([sys.executable,ROOT/"certified.py",str(n),hx,hz],check=True,
                                 capture_output=True,text=True)
            full = json.loads(got.stdout)
            if d is None:
                assert full == {"status":"EMPTY"}
            else:
                assert full["status"] == "FOUND" and full["distance"] == d
                x, z = int(full["x"][::-1],2), int(full["z"][::-1],2)
                assert (("X",x) in valid and z == 0) or (("Z",z) in valid and x == 0)
            claims = [("X",0),("Z",rng.randrange(1<<n))]
            claims += [el for el in valid if el[1].bit_count() == d][:1]
            claims += [el for el in valid if el[1].bit_count() != d][:1]
            for s,w in claims:
                ans = check(n,s,w)
                accept = (s,w) in valid and w.bit_count() == d
                assert (ans.get("distance") == d and ans["status"]=="FOUND") == accept
                if not accept:
                    assert ans == {"status":"UNKNOWN"}
                count += 1
        # Valid X weight 3, but Z weight 1. Accepting after checking X alone is unsound.
        rows(hx,[],3)
        rows(hz,[3,6],3)
        assert check(3,"X",7) == {"status":"UNKNOWN"}
        assert check(3,"Z",1)["distance"] == 1
        # A checked dual involution does not turn a budget exhaustion into EMPTY.
        rows(hx,[15],4)
        rows(hz,[15],4)
        assert check(4,"X",3,0) == {"status":"UNKNOWN"}
        assert check(4,"X",3)["distance"] == 2
    print(f"45 full raw-PCM brute-force comparisons and {count+4} replay challenges passed")


if __name__ == "__main__":
    test_all()
