#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# gcc
# apt-get update && apt-get install -y build-essential

gcc -shared -fPIC -Wall -Wextra -O2 hook.c -o libhook.so
gcc -Wall -Wextra -Wno-unused-result -O2 target.c -o target

echo "[demo] LD_PRELOAD with external binary (which)"
LD_PRELOAD="$PWD/libhook.so" which gcc

echo "[demo] LD_PRELOAD with local target"
LD_PRELOAD="$PWD/libhook.so" ./target
