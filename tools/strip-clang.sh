#!/bin/bash
#
# Strip clang tarball to include only what we need to speed up the
# decompression at toolchain resolution.

set -euo pipefail

curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
tar -xf clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
pushd clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04
mkdir bin-new
mv \
  bin/clang \
  bin/clang++ \
  bin/clang-17 \
  bin/ld.lld \
  bin/ld64.lld \
  bin/lld \
  bin/llvm-nm \
  bin-new
rm -rf bin lib libexec include share local
mv bin-new bin
strip bin/clang-17 bin/lld bin/llvm-nm
popd
tar -Jcf clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04-stripped.tar.xz clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04
sha256sum clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04-stripped.tar.xz > clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04-stripped.tar.xz.sha256
