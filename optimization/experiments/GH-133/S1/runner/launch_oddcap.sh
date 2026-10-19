#!/bin/bash
# GH-133 S1 launcher (runs on yfclab2 under nohup): phase 1 waits until >= 4 of the cores 100-123 are free and starts the
# -oddcap-skip Tier 1-4 panel on all free cores; phase 2 waits until that runner is done and >= 18 cores are free, then
# starts the oddcap Tier 5 runs (BB/LP, 6 h). Free = no distqldpc / prlimit / runner process pinned to the core.
cd /home/yfc/mac-agent-20261009/gh133-d8fcce8 || exit 1
BIN=/home/yfc/mac-agent-20261009/frozen/server-gh133-d8fcce8/distqldpc
OUT=/home/yfc/mac-agent-20261009/gh133-s1
free() { bash $OUT/free_cores.sh; }
log() { echo "$(date '+%F %T') $*" >> $OUT/launcher.log; }
log "phase 1: waiting for >= 4 free cores"
while :; do f=($(free)); [ ${#f[@]} -ge 4 ] && break; sleep 120; done
cpus=$(IFS=,; echo "${f[*]}")
log "phase 1: starting oddcap panel on cores $cpus"
nohup python3 -I s1_queue.py --bin $BIN --cpus "$cpus" --jobs jobs_oddcap.jsonl --out $OUT/oddcap > $OUT/oddcap.out 2>&1 < /dev/null &
while [ ! -f $OUT/oddcap/RUNNER_DONE ]; do sleep 120; done
log "phase 1 done: $(cat $OUT/oddcap/RUNNER_DONE)"
log "phase 2: waiting for >= 18 free cores"
while :; do f=($(free)); [ ${#f[@]} -ge 18 ] && break; sleep 120; done
cpus=$(IFS=,; echo "${f[*]:0:18}")
log "phase 2: starting oddcap tier5 on cores $cpus"
nohup python3 -I s1_queue.py --bin $BIN --cpus "$cpus" --jobs jobs_oddcap5.jsonl --out $OUT/oddcap5 > $OUT/oddcap5.out 2>&1 < /dev/null &
while [ ! -f $OUT/oddcap5/RUNNER_DONE ]; do sleep 300; done
log "phase 2 done: $(cat $OUT/oddcap5/RUNNER_DONE)"
