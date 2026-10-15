#!/bin/bash
# prints: <#solver procs> <#runner procs> <#running jobs (.started files)>
ssh -o BatchMode=yes -o ConnectTimeout=20 yfclab2 'cd ~/mac-agent-20261009/gh124-s0de; s=$(pgrep -u yfc -f "^/home/yfc/mac-agent-20261009/frozen/server-gh124-114b901/distqldp[c]" | wc -l); r=$(pgrep -u yfc -f "python3 runne[r]" | wc -l); j=$(ls out/*.started out2/*.started out3/*.started 2>/dev/null | wc -l); echo "$s $r $j"' < /dev/null
