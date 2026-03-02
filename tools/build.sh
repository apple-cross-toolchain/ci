#!/bin/bash

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_ROOT}/.." && pwd)"

sudo apt update -qq
DEBIAN_FRONTEND="noninteractive" sudo apt install -qqy --no-install-recommends \
  doxygen zip build-essential curl git cmake zlib1g-dev libpng-dev libxml2-dev \
  gobjc python3 python-is-python3 vim-tiny ca-certificates ninja-build patchelf \
  clang

mkdir -p out/lib out/bin

git clone https://github.com/apple-cross-toolchain/xcbuild-rust.git
pushd xcbuild-rust
git checkout 9173412d86270a2d026f7c1f49f7da6a1e1b8bae
cargo build --release
find target/release -maxdepth 1 -type f -executable -exec cp {} "$PROJECT_ROOT/out/bin" \;
popd
rm -rf xcbuild-rust

curl -L https://sourceforge.net/projects/pmt/files/pngcrush/1.8.13/pngcrush-1.8.13.tar.gz/download -o pngcrush.tar.gz
tar -xf pngcrush.tar.gz
rm -rf pngcrush.tar.gz
pushd pngcrush-1.8.13
make -j$(nproc)
mv pngcrush "$PROJECT_ROOT/out/bin"
popd
rm -rf pngcrush-1.8.13

git clone https://github.com/tpoechtrager/apple-libtapi.git
pushd apple-libtapi
git checkout 664b8414f89612f2dfd35a9b679c345aa5389026
INSTALLPREFIX="$PROJECT_ROOT/out" ./build.sh
./install.sh
popd
rm -rf apple-libtapi

git clone https://github.com/tpoechtrager/cctools-port.git
pushd cctools-port/cctools
git checkout faa1f24cb7e31be132f98f503cc447c90ce2fd87
./configure --prefix="$PROJECT_ROOT/out" --with-libtapi="$PROJECT_ROOT/out"
make -j$(nproc)
make -j$(nproc) install
# Add '../lib' to ld's rpath to make it portable
patchelf --set-rpath '$ORIGIN/../lib' "$PROJECT_ROOT/out/bin/ld"
# Remove cctools' dsymutil and nm; we use llvm-dsymutil and llvm-nm
rm -f "$PROJECT_ROOT/out/bin/dsymutil"
rm -f "$PROJECT_ROOT/out/bin/nm"
popd
rm -rf cctools-port

# Unported tools
cp tools/dummy_tool out/bin/codesign
cp tools/dummy_tool out/bin/ibtool
cp tools/dummy_tool out/bin/swift-stdlib-tool

cd out
archive_filename="ported-tools-"$(uname | tr '[:upper:]' '[:lower:]')"-"$(arch)".tar.xz"
tar -Jcf "$archive_filename" bin lib
sha256sum "$archive_filename" > "$archive_filename.sha256"
