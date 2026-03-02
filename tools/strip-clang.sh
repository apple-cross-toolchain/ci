#!/bin/bash
#
# Strip clang tarball to include only what we need to speed up the
# decompression at toolchain resolution.

set -euo pipefail

clang_tarball_root="LLVM-22.1.0-Linux-X64"
clang_tarball_file="${clang_tarball_root}.tar.xz"
clang_tarball_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.0/${clang_tarball_file}"

curl -LO "${clang_tarball_url}"
tar -xf "${clang_tarball_file}"
pushd "${clang_tarball_root}"
mkdir bin-new
for tool in clang clang++ ld.lld ld64.lld lld llvm-nm; do
  if [[ -e "bin/${tool}" ]]; then
    mv "bin/${tool}" bin-new
  fi
done

# Keep whichever versioned clang binary this LLVM release provides.
versioned_clang="$(find bin -maxdepth 1 -type f -name 'clang-[0-9]*' | head -n 1)"
if [[ -n "${versioned_clang}" ]]; then
  mv "${versioned_clang}" bin-new
fi

rm -rf bin lib libexec include share local
mv bin-new bin
if command -v strip >/dev/null 2>&1; then
  strip_targets=()
  for candidate in bin/*; do
    if [[ -f "${candidate}" && -x "${candidate}" ]]; then
      strip_targets+=("${candidate}")
    fi
  done

  if [[ ${#strip_targets[@]} -gt 0 ]]; then
    if strip --help 2>&1 | grep -q -- "--strip-debug"; then
      strip --strip-debug "${strip_targets[@]}"
    else
      strip "${strip_targets[@]}" || true
    fi
  fi
fi
popd
stripped_tarball_file="${clang_tarball_root}-stripped.tar.xz"
if ! tar -I "xz -T0 -9e" -cf "${stripped_tarball_file}" "${clang_tarball_root}"; then
  XZ_OPT="-9e -T0" tar -Jcf "${stripped_tarball_file}" "${clang_tarball_root}"
fi
sha256sum "${stripped_tarball_file}" > "${stripped_tarball_file}.sha256"
