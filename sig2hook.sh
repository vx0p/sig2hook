#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# patchelf gcc objdump
# apt-get update && apt-get install -y patchelf build-essential

gcc -Wall -Wextra -Wno-unused-result -O2 target.c -o target

cp target ill_target

# addのオフセットと先頭命令を取得
read -r OFFSET_HEX _ < <(objdump -d ill_target | grep -m 1 "<add>:")
OFFSET_DEC=$((16#$OFFSET_HEX))
echo "関数add: 0x$OFFSET_HEX (Decimal: $OFFSET_DEC)"

FIRST_WORD=$(
	objdump -d ill_target | awk '/<add>:/ {getline; print $2; exit}'
)
if [[ ! "${FIRST_WORD:-}" =~ ^[0-9a-fA-F]{8}$ ]]; then
	echo "先頭命令の取得に失敗しました: '$FIRST_WORD'" >&2
	exit 1
fi
echo "add先頭命令(.inst): 0x$FIRST_WORD"

# ill_targetに不正な命令(0x00000000)を書き込む
PAYLOAD='\x00\x00\x00\x00'
printf '%b' "$PAYLOAD" | dd of=ill_target \
	seek="$OFFSET_DEC" \
	bs=1 \
	count=4 \
	conv=notrunc \
	&>/dev/null
objdump -dC ./ill_target | grep -A 10 '<add>:'

echo "before patch"
./ill_target || rm -f qemu*.core

# ライブラリをビルド（命令はマクロで注入）
gcc -shared -fPIC -Wall -Wextra -O2 -DSIG2HOOK_INST=0x"$FIRST_WORD" sig2hook.c -o libsig2hook.so

# 実行ファイルにライブラリを追加
patchelf --set-rpath "\$ORIGIN" ./ill_target
patchelf --add-needed libsig2hook.so ./ill_target

echo "after patch"
./ill_target
