#!/usr/bin/env bash
#
# Copyright (c) 2025 Linaro Limited
#
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly aavmf_builder="${script_dir}/build-aavmf.sh"

source "${script_dir}/../../scripts/lib.sh"

DESTDIR=${DESTDIR:-${PWD}}
PREFIX=${PREFIX:-/opt/kata}
container_image="${AAVMF_CONTAINER_BUILDER:-$(get_aavmf_image_name)}"
aavmf_build="${aavmf_build:-aarch64}"
kata_version="${kata_version:-}"
aavmf_repo="${aavmf_repo:-}"
aavmf_version="${aavmf_version:-}"
aavmf_package="${aavmf_package:-}"
package_output_dir="${package_output_dir:-}"

if [ -z "$aavmf_repo" ]; then
	aavmf_repo=$(get_from_kata_deps ".externals.aavmf.url")
fi

[ -n "$aavmf_repo" ] || die "failed to get aavmf repo"

if [ "${aavmf_build}" == "aarch64" ]; then
	[ -n "$aavmf_version" ] || aavmf_version=$(get_from_kata_deps ".externals.aavmf.aarch64.version")
	[ -n "$aavmf_package" ] || aavmf_package=$(get_from_kata_deps ".externals.aavmf.aarch64.package")
	[ -n "$package_output_dir" ] || package_output_dir=$(get_from_kata_deps ".externals.aavmf.aarch64.package_output_dir")
fi

[ -n "$aavmf_version" ] || die "failed to get aavmf version or commit"
[ -n "$aavmf_package" ] || die "failed to get aavmf package or commit"
[ -n "$package_output_dir" ] || die "failed to get aavmf package or commit"

docker pull ${container_image} || \
	(docker build -t "${container_image}" "${script_dir}" && \
	# No-op unless PUSH_TO_REGISTRY is exported as "yes"
	push_to_registry "${container_image}")

docker run --rm -i -v "${repo_root_dir}:${repo_root_dir}" \
	-w "${PWD}" \
	--env DESTDIR="${DESTDIR}" --env PREFIX="${PREFIX}" \
	--env aavmf_build="${aavmf_build}" \
	--env aavmf_repo="${aavmf_repo}" \
	--env aavmf_version="${aavmf_version}" \
	--env aavmf_package="${aavmf_package}" \
	--env package_output_dir="${package_output_dir}" \
	--user "$(id -u)":"$(id -g)" \
	"${container_image}" \
	bash -c "${aavmf_builder}"
