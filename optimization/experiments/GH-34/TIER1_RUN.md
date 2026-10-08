# GH-34 Tier1 run record (written before launch)

Host: Apple M6 Mac mini, 12 logical CPUs, macOS 27 (Darwin 27.0.0), Apple clang 21.0.0.
Runner: `mac-litvals-20261009`, the only runner on this host (user-authorised directly).
Frozen binaries (built at a1b90ad / baseline 24572d6, never rebuilt for timing):
- baseline  `../base/bin/distqldpc`  ac43af52144330f72d838667c82851511bc208f1cb35966359126c2d6a69eb26
- candidate `bin/distqldpc`          0549c4ecc9cdf65fa807a1a7556667787bedcebdff674ed2296032168fc61b8b

Command (from the candidate worktree root, so `data/matrices` is the pinned input):

    python3 -I optimization/experiments/GH-34/tier1_mac.py \
      --base ../base/bin/distqldpc --cand bin/distqldpc \
      --out optimization/experiments/GH-34/raw/tier1-01 --replicate 10

Exactly as preregistered in PROPOSAL.md: BB_90_8_10, GB_144_12_8, BB_108_8_10,
LP_238_44_6; `-no-card` and `-card-mto`; gate phase 3+3 AB/BA/AB per case/mode
(48 solves), then 10 alternating AB/BA pairs per case/mode (160 solves,
supplementary, reported separately). `-cpu-lim=180`, watchdog 195 s, one solve at
a time, start only when 1-min load < 6.0 (wait up to 600 s, else stop and
record INCONCLUSIVE). Every run's exit code, `o N`, and all emitted progress/bound
lines must equal the expected distance and match across versions, else STOP/REJECT.
Telemetry per run: load averages before/after and summed `ps` %CPU before.
Judge: unchanged GH16 rule (per mode all medians non-worse AND range-envelope
geomean < 1 => numerically positive; nonoverlapping-regression flag per case).
Interactive desktop host, no CPU pinning: diagnostic, not controlled evidence.
Single attempt; no reruns to obtain a different outcome.
