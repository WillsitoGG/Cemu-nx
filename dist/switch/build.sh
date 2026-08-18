#!/usr/bin/env bash
set -euo pipefail

export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
SWITCH_BUILD_DIR="${SWITCH_BUILD_DIR:-build_switch}"
RELEASE_VERSION="${RELEASE_VERSION:-1.1.3}"
case "${BUILD_JOBS}" in
	''|*[!0-9]*|0) echo "BUILD_JOBS must be a positive integer" >&2; exit 2 ;;
esac
if [[ ! "$RELEASE_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
	echo "RELEASE_VERSION must use major.minor.patch format" >&2
	exit 2
fi
VERSION_MAJOR="${BASH_REMATCH[1]}"
VERSION_MINOR="${BASH_REMATCH[2]}"
VERSION_PATCH="${BASH_REMATCH[3]}"
cd "${ROOT}"

bash "${ROOT}/dist/switch/deps/prepare_submodules.sh"

echo ">> Localizing NVK driver symbols ..."
bash "${ROOT}/dist/switch/deps/prepare_nvk.sh"

cmake -S . -B "${SWITCH_BUILD_DIR}" -G Ninja \
	-DCMAKE_TOOLCHAIN_FILE="${ROOT}/cmake/Toolchain-Switch.cmake" \
	-DCMAKE_BUILD_TYPE=Release \
	-DEMULATOR_VERSION_MAJOR="${VERSION_MAJOR}" \
	-DEMULATOR_VERSION_MINOR="${VERSION_MINOR}" \
	-DEMULATOR_VERSION_PATCH="${VERSION_PATCH}" \
	-DENABLE_OPENGL=ON \
	-DENABLE_VULKAN=ON \
	-DSWITCH_MESA_SDK_ROOT="${SWITCH_MESA_SDK_ROOT:-${ROOT}/dependencies/switch_mesa_vulkan}" \
	-DSWITCH_LTO_JOBS="${BUILD_JOBS}"

cmake --build "${SWITCH_BUILD_DIR}" --parallel "${BUILD_JOBS}" --target CemuNro

echo ">> Output: ${ROOT}/bin/cemu_core.nro"
