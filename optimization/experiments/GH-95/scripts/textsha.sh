#!/bin/zsh
# print __text size and sha256 of the __TEXT,__text section bytes
f="$1"
otool -l "$f" | awk '/sectname __text/{f=1} f&&/size/{print $2; exit}' | read sz
otool -l "$f" | awk '/sectname __text/{f=1} f&&/offset/{print $2; exit}' | read off
sz=$((sz))
echo "size=$sz sha=$(dd if="$f" bs=1 skip=$off count=$sz 2>/dev/null | shasum -a 256 | cut -c1-16)"
