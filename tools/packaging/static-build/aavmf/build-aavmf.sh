#!/bin/bash
#
# Copyright (c) 2025 Linaro Limited
#
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/../../scripts/lib.sh"

# disabling set -u because scripts attempt to expand undefined variables
set +u
aavmf_build="${aavmf_build:-aarch64}"
aavmf_repo="${aavmf_repo:-}"
aavmf_version="${aavmf_version:-}"
aavmf_package="${aavmf_package:-}"
package_output_dir="${package_output_dir:-}"
DESTDIR=${DESTDIR:-${PWD}}
PREFIX="${PREFIX:-/opt/kata}"
architecture="${architecture:-AARCH64}"
toolchain="${toolchain:-GCC5}"
build_target="${build_target:-RELEASE}"

[ -n "$aavmf_repo" ] || die "failed to get aavmf repo"
[ -n "$aavmf_version" ] || die "failed to get aavmf version or commit"
[ -n "$aavmf_package" ] || die "failed to get aavmf package or commit"
[ -n "$package_output_dir" ] || die "failed to get aavmf package or commit"

aavmf_dir="${aavmf_repo##*/}"

info "Build ${aavmf_repo} version: ${aavmf_version}"

build_root=$(mktemp -d)
pushd $build_root
git clone --single-branch --depth 1 -b "${aavmf_version}" "${aavmf_repo}"
cd "${aavmf_dir}"
git submodule init
git submodule update

info "Using BaseTools make target"
make -C BaseTools/

info "Calling edksetup script"
source edksetup.sh

info "Building aavmf"
build_cmd="build -b ${build_target} -t ${toolchain} -a ${architecture} -p ${aavmf_package}"

eval "${build_cmd}"

info "Done Building"

build_path_target_toolchain="Build/${package_output_dir}/${build_target}_${toolchain}"
build_path_fv="${build_path_target_toolchain}/FV"
stat "${build_path_fv}/QEMU_EFI.fd"
stat "${build_path_fv}/QEMU_VARS.fd"

#need to leave tmp dir
popd

info "Install fd to destdir"
install_dir="${DESTDIR}/${PREFIX}/share/AAVMF"

mkdir -p "${install_dir}"
install $build_root/$aavmf_dir/"${build_path_fv}"/QEMU_EFI.fd "${install_dir}"/AAVMF_CODE.fd
install $build_root/$aavmf_dir/"${build_path_fv}"/QEMU_VARS.fd "${install_dir}"/AAVMF_VARS.fd

# QEMU expects 64MiB CODE and VARS files on ARM/AARCH64 architectures
# Truncate the firmware files to the expected size
truncate -s 64M ${install_dir}/AAVMF_CODE.fd
truncate -s 64M ${install_dir}/AAVMF_VARS.fd

local_dir=${PWD}
pushd $DESTDIR
tar -czvf "${local_dir}/${aavmf_dir}-${aavmf_build}.tar.gz" "./$PREFIX"
rm -rf $(dirname ./$PREFIX)
popd
