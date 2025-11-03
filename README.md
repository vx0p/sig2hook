# sig2hook

[`sigaction`](https://linuxjm.sourceforge.io/html/LDP_man-pages/man2/sigaction.2.html)を使用した関数 hook

## 環境

ARM64

```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
docker run --platform linux/arm64 -it ubuntu
```

## 準備

```bash
apt-get update && apt-get install -y patchelf build-essential
```

## 実行

```bash
./sig2hook.sh
```

## 流れ

- 処理を埋め込みたい箇所に、存在しない命令（例えば、`0x00000000`）を書き込むと、通常であればプログラムがクラッシュ
- `sigaction`で捕捉することで自作ライブラリの関数に強制的にジャンプ
- コンテキストのレジスタの値を調整することで、実行ファイルに処理を戻す
