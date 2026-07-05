#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)"

export PATH=/usr/lib/llvm-23/bin/:$PATH

clang -v
clang++ -v
git -v

touch .scmversion
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION =/' Makefile

export KBUILD_BUILD_USER=ZakoBai♡
export KBUILD_BUILD_HOST=XinRan

case "${1:-build}" in
  build)
    make LLVM=1 LLVM_IAS=1 ARCH=arm64       CC="ccache clang" HOSTCC="ccache clang" HOSTCXX="ccache clang++"       LD=ld.lld HOSTLD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump       STRIP=llvm-strip READELF=llvm-readelf PYTHON=python3       O=out gki_defconfig

    make LLVM=1 LLVM_IAS=1 ARCH=arm64       CC="ccache clang" HOSTCC="ccache clang" HOSTCXX="ccache clang++"       LD=ld.lld HOSTLD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump       STRIP=llvm-strip READELF=llvm-readelf PYTHON=python3       O=out KCFLAGS="-Wno-error -Wno-unused-but-set-variable"       -j"$(nproc --all)"
    ;;
  clean)
    rm -rf out .scmversion
    ;;
  *)
    echo "usage: $0 [build|clean]" >&2
    exit 1
    ;;
esac
