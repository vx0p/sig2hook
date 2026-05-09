# sig2hook

[`sigaction`](https://linuxjm.sourceforge.io/html/LDP_man-pages/man2/sigaction.2.html)を使用した関数 hook

## 環境

arm64 向けの Docker コンテナを実行するための準備

```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

### ビルド

ビルド済みのイメージ`ghcr.io/vx0p/sig2hook:latest`を使用する場合は不要です。

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
  - Ubuntu 24.04.3 LTS (Noble Numbat)
  - ARM64

```bash
git clone https://github.com/vx0p/sig2hook.git
cd sig2hook
docker build --platform linux/arm64 -t sig2hook:latest .
```

## 実行

```bash
docker run --platform linux/arm64 -it --rm sig2hook:latest bash
# or
docker run --platform linux/arm64 -it --rm ghcr.io/vx0p/sig2hook:latest bash

# apt や vim を使用するなら
# docker run --platform linux/arm64 -it --rm --user root -v "$PWD":/sig2hook -w /sig2hook --entrypoint bash sig2hook:latest
```

### [sig2hook.sh](./sig2hook.sh)

```bash
./sig2hook.sh
```

<details>
<summary>実行結果</summary>

```bash
関数add: 0x00000000000008a0 (Decimal: 2208)
add先頭命令(.inst): 0xd10043ff
00000000000008a0 <add>:
 8a0:   00000000        udf     #0
 8a4:   b9000fe0        str     w0, [sp, #12]
 8a8:   b9000be1        str     w1, [sp, #8]
 8ac:   b9400fe1        ldr     w1, [sp, #12]
 8b0:   b9400be0        ldr     w0, [sp, #8]
 8b4:   0b000020        add     w0, w1, w0
 8b8:   910043ff        add     sp, sp, #0x10
 8bc:   d65f03c0        ret

Disassembly of section .fini:
before patch
qemu: uncaught target signal 4 (Illegal instruction) - core dumped
./sig2hook.sh: line 39: 264553 Illegal instruction     (core dumped) ./ill_target
after patch
== [libsig2hook] loaded ==
puts: target
printf: 1 + 2 = 7777777
write: finish
== [libsig2hook] unloading ==
```

</details>

### 処理の流れ - [sig2hook.sh](./sig2hook.sh)

- 処理を埋め込みたい箇所に、存在しない命令（例えば、`0x00000000`）を書き込むと、通常であればプログラムがクラッシュ
- `sigaction`で捕捉することでライブラリ`libsig2hook.so`の関数に強制的にジャンプ
- コンテキストのレジスタの値を調整することで、実行可能ファイル`target`に処理を戻す

### [patch.sh](./patch.sh)

`patchelf`を使用し、実行可能ファイル`target`のライブラリリストに`libhook.so`を追加

```bash
./patch.sh
```

<details>
<summary>実行結果</summary>

```bash
before patch
puts: target
printf: 1 + 2 = 3
write: finish
after patch
== [libhook] loaded ==
[HOOKED] puts: target
printf: 1 + 2 = 3
[HOOKED] write: finish
== [libhook] unloading ==
```

</details>

### [runtime.sh](./runtime.sh)

`LD_PRELOAD="$PWD/libhook.so"`によって、実行可能ファイル`target`には変更を加えず、実行時に`libhook.so`をロード

```bash
./runtime.sh
```

<details>
<summary>実行結果</summary>

```bash
[demo] LD_PRELOAD with external binary (which)
== [libhook] loaded ==
[HOOKED] /usr/bin/gcc
[demo] LD_PRELOAD with local target
== [libhook] loaded ==
[HOOKED] puts: target
printf: 1 + 2 = 3
[HOOKED] write: finish
== [libhook] unloading ==
```

</details>
