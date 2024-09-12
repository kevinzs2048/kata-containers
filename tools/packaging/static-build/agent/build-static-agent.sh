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

build_agent_from_source() {
	echo "build agent from source"

	cd src/agent
	echo "DESTDIR=${DESTDIR} AGENT_POLICY=yes SECCOMP=no PULL_TYPE=guest-pull"
	DESTDIR=${DESTDIR} AGENT_POLICY=yes SECCOMP=no PULL_TYPE=guest-pull make
	DESTDIR=${DESTDIR} AGENT_POLICY=yes SECCOMP=no PULL_TYPE=guest-pull make install
}

build_agent_from_source "$@"
