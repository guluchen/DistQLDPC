#!/usr/bin/env bash
# DistQLDPC web demo build: web/dq.js + web/dq.wasm (Emscripten), web/codes/*.json (bundled codes), web/version.json.
# Needs the Emscripten SDK in PATH (source <emsdk>/emsdk_env.sh), python3 and make.
#   web/build.sh                 # build into web/
#   JOBS=8 web/build.sh          # parallel compile
#   DQ_COMMIT=abc123 web/build.sh  # commit id to show when the tree is not a git checkout
# Copyright (C) 2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "$(dirname "$0")/.."
command -v em++ >/dev/null || { echo "em++ not found: source <emsdk>/emsdk_env.sh first" >&2; exit 1; }
COMMIT="${DQ_COMMIT:-$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)}"
EMV="$(em++ --version | head -1 | sed -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
rm -f web/dq.js web/dq.wasm build/wasm/dq_api.o
make -j"${JOBS:-4}" wasm GIT_COMMIT="$COMMIT"
python3 scripts/web_export_codes.py --out web/codes --timings web/timings.json
printf '{"commit": "%s", "date": "%s", "emcc": "%s"}\n' "$COMMIT" "$(date -u +%Y-%m-%d)" "$EMV" > web/version.json
ls -l web/dq.js web/dq.wasm web/version.json
du -sh web/codes
