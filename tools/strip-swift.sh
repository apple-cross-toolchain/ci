#!/bin/bash
#
# Strip swift tarball to include only what we need to speed up the
# decompression at toolchain resolution.

set -euo pipefail

curl -LO https://download.swift.org/swift-6.2.3-release/ubuntu2204/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE-ubuntu22.04.tar.gz
tar -xf swift-6.2.3-RELEASE-ubuntu22.04.tar.gz
pushd swift-6.2.3-RELEASE-ubuntu22.04/usr
mkdir bin-new
mv \
  bin/swift \
  bin/swiftc \
  bin/swift-build \
  bin-new
rm -rf bin lib libexec include share
mv bin-new bin
popd
tar -Jcf swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz swift-6.2.3-RELEASE-ubuntu22.04
sha256sum swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz > swift-6.2.3-RELEASE-ubuntu22.04-stripped.tar.xz.sha256
