#!/usr/bin/env bash
#
# Copyright (c) 2023 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/../../scripts/lib.sh"

SECCOMP=${SECCOMP:-yes}

init_env() {
	source "$HOME/.cargo/env"

	ARCH=$(uname -m)
	rust_arch=""
	case ${ARCH} in
		"aarch64")
			export LIBC=musl
			rust_arch=${ARCH}
			;;
		"ppc64le")
			export LIBC=gnu
			rust_arch="powerpc64le"
			;;
		"x86_64")
			export LIBC=musl
			rust_arch=${ARCH}
			;;
		"s390x")
			export LIBC=gnu
			rust_arch=${ARCH}
			;;
	esac
	rustup target add ${rust_arch}-unknown-linux-${LIBC}

}

build_agent_from_source() {
	echo "build agent from source"

	init_env

	if [ ${SECCOMP} = yes ] ; then \
		export LIBSECCOMP_LINK_TYPE=static
		export LIBSECCOMP_LIB_PATH=/usr/lib
		/usr/bin/install_libseccomp.sh /usr /usr ;
	fi

	cd src/agent
	DESTDIR=${DESTDIR} AGENT_POLICY=${AGENT_POLICY} SECCOMP=${SECCOMP} make
	DESTDIR=${DESTDIR} AGENT_POLICY=${AGENT_POLICY} SECCOMP=${SECCOMP} make install
}

build_agent_from_source $@
