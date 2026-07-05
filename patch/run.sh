#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PATCH_DIR="$ROOT/patch"
WORKTREE="$ROOT/../.worktrees/common-clang23"
OUT_DIR="$ROOT/out/clang23"
JOBS="${JOBS:-$(nproc)}"

prepare() {
  mkdir -p "$(dirname "$WORKTREE")" "$OUT_DIR"
  if [ ! -e "$WORKTREE/.git" ]; then
    git -C "$ROOT" worktree add --force --detach "$WORKTREE" HEAD >/dev/null
  fi
  git -C "$WORKTREE" reset --hard HEAD >/dev/null
  git -C "$WORKTREE" clean -fd >/dev/null
  for patch in "$PATCH_DIR"/*.patch; do
    [ -e "$patch" ] && git -C "$WORKTREE" apply "$patch"
  done
  sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION =/' "$WORKTREE/Makefile"
  export KBUILD_BUILD_USER='ZakoBai♡'
  export KBUILD_BUILD_HOST='XinRan'
}

make_cmd() {
  make -C "$WORKTREE" O="$OUT_DIR" \
    ARCH=arm64 LLVM=0 LLVM_IAS=1 \
    CC=clang-23 HOSTCC=clang-23 HOSTCXX=clang++-23 \
    LD=ld.bfd HOSTLD=ld.bfd \
    AR=llvm-ar-23 NM=llvm-nm-23 OBJCOPY=llvm-objcopy-23 OBJDUMP=llvm-objdump-23 \
    STRIP=llvm-strip-23 READELF=llvm-readelf-23 \
    KCFLAGS=-Wno-error HOSTCFLAGS=-Wno-error \
    "$@"
}

case "${1:-build}" in
  build)
    prepare
    make_cmd gki_defconfig
    make_cmd -j"$JOBS" Image Image.gz Image.lz4 modules
    echo "$OUT_DIR/arch/arm64/boot"
    ;;
  clean)
    git -C "$ROOT" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
    rm -rf "$OUT_DIR"
    ;;
  *)
    echo "usage: $0 [build|clean]" >&2
    exit 1
    ;;
esac
