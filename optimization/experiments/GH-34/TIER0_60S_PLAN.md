# GH-34 preregistered 60 s trace-identity check (plan, written before running)

Completes the PROPOSAL.md Tier0 item 3 rule ("byte-identical for every case that
finishes within 60 s"), which the 20 s sweep did not satisfy. Same frozen binaries.
Stems: the 38 codes with any timed-out comparison at 20 s (`raw/tier0-60s-stems.txt`),
all four modes, `-cpu-lim=60`, 4 comparisons in parallel (<= half of spare CPU).
Rules fixed now: completed comparisons must be byte-identical (stdout, stderr, exit
code) and report the named distance where the name gives one; timed-out pairs are
judged with the corrected comparator `rejudge_trace_identity.py` (child output
prefix-consistent, TIMEOUT trailer in both, bounds not contradicting a named
distance; xu_*/PK_* names carry no distance). Any violation = STOP/REJECT.
