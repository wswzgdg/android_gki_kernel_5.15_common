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
  : > "$WORKTREE/.scmversion"
  export KBUILD_BUILD_USER='ZakoBai♡'
  export KBUILD_BUILD_HOST='XinRan'
}

pick_bin() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 && {
      printf '%s' "$bin"
      return 0
    }
  done
  return 1
}

make_cmd() {
  local cc hostcxx ld ar nm objcopy objdump strip readelf
  cc="$(pick_bin clang-23 clang-22 clang-21 clang)"
  hostcxx="$(pick_bin clang++-23 clang++-22 clang++-21 clang++)"
  ld="$(pick_bin ld.bfd ld.lld ld)"
  ar="$(pick_bin llvm-ar-23 llvm-ar)"
  nm="$(pick_bin llvm-nm-23 llvm-nm)"
  objcopy="$(pick_bin llvm-objcopy-23 llvm-objcopy)"
  objdump="$(pick_bin llvm-objdump-23 llvm-objdump)"
  strip="$(pick_bin llvm-strip-23 llvm-strip)"
  readelf="$(pick_bin llvm-readelf-23 llvm-readelf)"

  make -C "$WORKTREE" O="$OUT_DIR" \
    ARCH=arm64 LLVM=0 LLVM_IAS=1 \
    CC="$cc" HOSTCC="$cc" HOSTCXX="$hostcxx" \
    LD="$ld" HOSTLD="$ld" \
    AR="$ar" NM="$nm" OBJCOPY="$objcopy" OBJDUMP="$objdump" \
    STRIP="$strip" READELF="$readelf" \
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
