#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# patchelf
# apt-get update && apt-get install -y patchelf

gcc -shared -fPIC -Wall -Wextra -O2 hook.c -o libhook.so
gcc -Wall -Wextra -Wno-unused-result -O2 target.c -o target

echo "before patch"
./target

# ライブラリを見つけられるように実行可能ファイルにRPATHを設定
patchelf --set-rpath '$ORIGIN' ./target
patchelf --add-needed libhook.so ./target

echo "after patch"
./target
