#!/bin/bash
#
# Strip swift tarball to include only what we need to speed up the
# decompression at toolchain resolution.

set -euo pipefail

swift_tarball_root="swift-6.2.3-RELEASE-ubuntu24.04"
swift_tarball_file="${swift_tarball_root}.tar.gz"
swift_tarball_url="https://download.swift.org/swift-6.2.3-release/ubuntu2404/swift-6.2.3-RELEASE/${swift_tarball_file}"

curl -LO "${swift_tarball_url}"
tar -xf "${swift_tarball_file}"
pushd "${swift_tarball_root}/usr"
mkdir bin-new
mv bin/swift-driver bin/swift-frontend bin/swift-package \
   bin/swift-autolink-extract bin-new
ln -s swift-driver bin-new/swift
ln -s swift-driver bin-new/swiftc
ln -s swift-package bin-new/swift-build
# Preserve lib/swift/linux/ (host runtime .so files that swift-driver
# and swift-frontend need at runtime) and lib/swift/host/ (libSwiftScan
# and SwiftSyntax libs used by the dependency scanner).
if [[ -d lib/swift/linux ]]; then
  mv lib/swift/linux lib-swift-linux-save
fi
if [[ -d lib/swift/host ]]; then
  mv lib/swift/host lib-swift-host-save
fi
rm -rf bin lib libexec include share local
mv bin-new bin
mkdir -p lib/swift
if [[ -d lib-swift-linux-save ]]; then
  mv lib-swift-linux-save lib/swift/linux
fi
if [[ -d lib-swift-host-save ]]; then
  mv lib-swift-host-save lib/swift/host
fi
if command -v strip >/dev/null 2>&1; then
  strip_targets=(bin/swift-driver bin/swift-package bin/swift-frontend
                 bin/swift-autolink-extract)
  if strip --help 2>&1 | grep -q -- "--strip-debug"; then
    strip --strip-debug "${strip_targets[@]}"
  else
    strip "${strip_targets[@]}" || true
  fi
fi
popd
stripped_tarball_file="${swift_tarball_root}-stripped.tar.xz"
if ! tar -I "xz -T0 -9e" -cf "${stripped_tarball_file}" "${swift_tarball_root}"; then
  XZ_OPT="-9e -T0" tar -Jcf "${stripped_tarball_file}" "${swift_tarball_root}"
fi
sha256sum "${stripped_tarball_file}" > "${stripped_tarball_file}.sha256"
