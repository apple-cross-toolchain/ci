#!/bin/bash
#
# Strip swift tarball to include only what we need to speed up the
# decompression at toolchain resolution.

set -euo pipefail

curl -LO https://download.swift.org/swift-6.2.3-release/ubuntu2204/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE-ubuntu22.04.tar.gz
tar -xf swift-6.2.3-RELEASE-ubuntu22.04.tar.gz
pushd swift-6.2.3-RELEASE-ubuntu22.04/usr
mkdir bin-new
mv bin/swift-driver bin/swift-package bin-new
ln -s swift-driver bin-new/swift
ln -s swift-driver bin-new/swiftc
ln -s swift-package bin-new/swift-build
rm -rf bin lib libexec include share local
mv bin-new bin
strip bin/swift-driver bin/swift-package
popd
tar -Jcf swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz swift-6.2.3-RELEASE-ubuntu22.04
sha256sum swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz > swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz.sha256
