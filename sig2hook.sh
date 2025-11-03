#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# patchelf objdump
# apt-get update && apt-get install -y patchelf build-essential

gcc -shared -fPIC -Wall -Wextra -O2 sig2hook.c -o libsig2hook.so
gcc -Wall -Wextra -Wno-unused-result -O2 target.c -o target

cp target ill_target

read -r OFFSET_HEX _ < <(objdump -d ill_target | grep -m 1 "<add>:")
OFFSET_DEC=$((16#$OFFSET_HEX))
echo "関数add: 0x$OFFSET_HEX (Decimal: $OFFSET_DEC)"

PAYLOAD='\x00\x00\x00\x00'
printf "$PAYLOAD" | dd of=ill_target \
	seek="$OFFSET_DEC" \
	bs=1 \
	count=4 \
	conv=notrunc \
	&>/dev/null
objdump -dC ./ill_target | grep -A 10 '<add>:'

echo "before patch"
./ill_target || rm -f qemu*.core

patchelf --set-rpath '$ORIGIN' ./ill_target
patchelf --add-needed libsig2hook.so ./ill_target

echo "after patch"
./ill_target
