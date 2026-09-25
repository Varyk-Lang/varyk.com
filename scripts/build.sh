#!/usr/bin/env bash
# Build the site into public/. Uses zola from PATH when it is the pinned
# version; otherwise downloads that version into .zola/ and verifies it.
set -euo pipefail
cd "$(dirname "$0")/.."

ZOLA_VERSION=0.23.6

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    target=x86_64-unknown-linux-gnu
    sha256=8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4
    ;;
  Darwin-arm64)
    target=aarch64-apple-darwin
    sha256=cbffbd29b3f59c3f52633507c8cb945a7a02d8b1399b43b235f5932912297aa3
    ;;
  *)
    echo "build.sh: no pinned zola download for $(uname -s)-$(uname -m); put zola $ZOLA_VERSION on PATH" >&2
    exit 1
    ;;
esac

is_pinned() { "$1" --version 2>/dev/null | grep -q "zola $ZOLA_VERSION\$"; }

if command -v zola >/dev/null && is_pinned zola; then
  zola=zola
else
  zola=.zola/zola
  if ! [ -x "$zola" ] || ! is_pinned "$zola"; then
    tarball="zola-v$ZOLA_VERSION-$target.tar.gz"
    mkdir -p .zola
    curl -sSfL -o ".zola/$tarball" \
      "https://github.com/getzola/zola/releases/download/v$ZOLA_VERSION/$tarball"
    if command -v sha256sum >/dev/null; then
      actual=$(sha256sum ".zola/$tarball" | cut -d ' ' -f 1)
    else
      actual=$(shasum -a 256 ".zola/$tarball" | cut -d ' ' -f 1)
    fi
    if [ "$actual" != "$sha256" ]; then
      echo "build.sh: checksum mismatch for $tarball" >&2
      exit 1
    fi
    tar -xzf ".zola/$tarball" -C .zola zola
    rm ".zola/$tarball"
  fi
fi

"$zola" --version
"$zola" build --force

if [ -f scripts/agents.sh ]; then
  bash scripts/agents.sh
fi
