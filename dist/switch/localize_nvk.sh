#!/usr/bin/env bash
# Localize Mesa's Vulkan exports so they do not collide with Cemu's dispatch table.
set -euo pipefail

DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
BIN="${DEVKITPRO}/devkitA64/bin"
LD="${BIN}/aarch64-none-elf-ld"
OBJCOPY="${BIN}/aarch64-none-elf-objcopy"
NM="${BIN}/aarch64-none-elf-nm"
AR="${BIN}/aarch64-none-elf-ar"

HERE="$(cd "${1:-$(dirname "$0")/../../dependencies/switch_mesa_vulkan}" && pwd)"
LIBDIR="${HERE}/lib"
MERGED="${HERE}/libnvk_merged.o"
LOCAL="${HERE}/libnvk_local.o"
LOCAL_CANDIDATE="${HERE}/libnvk_local.o.tmp"
LOCAL_ARCHIVE="${HERE}/libnvk_local.a"
LOCAL_ARCHIVE_CANDIDATE="${HERE}/libnvk_local.a.tmp"
PUBLIC_VK_SYMBOLS="${HERE}/libnvk_public_symbols.txt.tmp"
CHECKSUMS="${HERE}/share/nvk-switch/SHA256SUMS"

cleanup() {
	rm -f "${MERGED}" "${LOCAL_CANDIDATE}" \
		"${LOCAL_ARCHIVE_CANDIDATE}" "${PUBLIC_VK_SYMBOLS}"
}
trap cleanup EXIT

if [[ -f "${LIBDIR}/libvulkan.a" ]] &&
   [[ "$(head -c 8 "${LIBDIR}/libvulkan.a")" == '!<arch>'* ]]; then
	echo "Merging unified Mesa Vulkan archive from ${LIBDIR} ..."
	"${LD}" -r \
		-u vk_icdGetInstanceProcAddr \
		-u vk_icdNegotiateLoaderICDInterfaceVersion \
		-u vk_icdGetPhysicalDeviceProcAddr \
		-u nvk_loaderless_GetInstanceProcAddr \
		-u nvk_loaderless_GetDeviceProcAddr \
		--start-group "${LIBDIR}/libvulkan.a" --end-group \
		-o "${MERGED}"
else
REQUIRED_ARCHIVES=(
	libnvk.a libvulkan_wsi.a libvulkan_runtime.a libvulkan_instance.a
	libvulkan_util.a libvulkan_lite_runtime.a libvulkan_lite_instance.a
	libnil.a liblibnil_format_table.a libnak.a libnak_rs.a libnouveau_mme.a
	libnouveau_ws.a libnvidia_headers_c.a libnir.a libvtn.a libcompiler.a
	libcompiler_c_helpers.a libblake3.a libmesa_util.a libmesa_util_simd.a
	libmesa_util_c11.a
	libxmlconfig.a
)
for archive in "${REQUIRED_ARCHIVES[@]}"; do
	if [[ ! -f "${LIBDIR}/${archive}" ]]; then
		echo "Missing NVK archive: ${LIBDIR}/${archive}" >&2
		echo "See dist/switch/README.md for the required private NVK archives." >&2
		exit 1
	fi
done

if [[ -f "${CHECKSUMS}" ]]; then
	(
		cd "${HERE}"
		tr -d '\r' < "${CHECKSUMS}" | sha256sum --check --strict -
	)
fi

echo "Merging NVK archives from ${LIBDIR} ..."
# Mesa 26.1's libnvk.a embeds some runtime and WSI members. Extract it in full,
# then let the archive group supply only still-unresolved dependencies.
"${LD}" -r \
	--whole-archive \
	"${LIBDIR}/libnvk.a" \
	--no-whole-archive \
	--start-group \
	"${LIBDIR}/libvulkan_wsi.a" \
	"${LIBDIR}/libvulkan_runtime.a" \
	"${LIBDIR}/libvulkan_instance.a" \
	"${LIBDIR}/libvulkan_util.a" \
	"${LIBDIR}/libvulkan_lite_runtime.a" \
	"${LIBDIR}/libvulkan_lite_instance.a" \
	"${LIBDIR}/libnil.a" \
	"${LIBDIR}/liblibnil_format_table.a" \
	"${LIBDIR}/libnak.a" \
	"${LIBDIR}/libnak_rs.a" \
	"${LIBDIR}/libnouveau_mme.a" \
	"${LIBDIR}/libnouveau_ws.a" \
	"${LIBDIR}/libnvidia_headers_c.a" \
	"${LIBDIR}/libnir.a" \
	"${LIBDIR}/libvtn.a" \
	"${LIBDIR}/libcompiler.a" \
	"${LIBDIR}/libcompiler_c_helpers.a" \
	"${LIBDIR}/libblake3.a" \
	"${LIBDIR}/libmesa_util.a" \
	"${LIBDIR}/libmesa_util_simd.a" \
	"${LIBDIR}/libmesa_util_c11.a" \
	"${LIBDIR}/libxmlconfig.a" \
	--end-group \
	-o "${MERGED}"
fi

# Cemu's Vulkan dispatch table defines public vk* function-pointer variables,
# so Mesa's public Vulkan entrypoints must be private.  Do not localize every
# other Mesa symbol: EGL/Zink and NVK must share one Horizon runtime, winsys,
# device and allocation lifetime graph inside the unified executable.
"${NM}" -g --defined-only "${MERGED}" | \
	awk '$NF ~ /^vk[A-Z]/ { print $NF }' | LC_ALL=C sort -u > "${PUBLIC_VK_SYMBOLS}"
if [[ ! -s "${PUBLIC_VK_SYMBOLS}" ]]; then
	echo "Mesa Vulkan object has no public entrypoints to localize" >&2
	exit 1
fi
# Mesa's Rust support and Cemu both provide these POSIX compatibility helpers.
# Keeping Mesa's copies private does not split the shared Horizon runtime.
printf '%s\n' writev posix_memalign >> "${PUBLIC_VK_SYMBOLS}"
LC_ALL=C sort -u -o "${PUBLIC_VK_SYMBOLS}" "${PUBLIC_VK_SYMBOLS}"

echo "Localizing public Vulkan API symbols while retaining shared Mesa state ..."
"${OBJCOPY}" --localize-symbols="${PUBLIC_VK_SYMBOLS}" \
	"${MERGED}" "${LOCAL_CANDIDATE}"

for symbol in \
	vk_icdGetInstanceProcAddr \
	vk_icdNegotiateLoaderICDInterfaceVersion \
	vk_icdGetPhysicalDeviceProcAddr \
	nvk_loaderless_GetInstanceProcAddr \
	nvk_loaderless_GetDeviceProcAddr \
	nouveau_horizon_runtime_get; do
	if ! "${NM}" -g --defined-only "${LOCAL_CANDIDATE}" | \
		awk -v expected="${symbol}" '$NF == expected { found = 1 } END { exit !found }'; then
		echo "Localized Mesa object is missing shared symbol ${symbol}" >&2
		exit 1
	fi
done
if "${NM}" -g --defined-only "${LOCAL_CANDIDATE}" | \
	awk '$NF ~ /^vk[A-Z]/ { found = 1 } END { exit !found }'; then
	echo "Localized Mesa object still exports a public Vulkan entrypoint" >&2
	exit 1
fi

candidate_hash="$(sha256sum "${LOCAL_CANDIDATE}" | cut -d ' ' -f 1)"
local_hash=""
if [[ -f "${LOCAL}" ]]; then
	local_hash="$(sha256sum "${LOCAL}" | cut -d ' ' -f 1)"
fi
if [[ "${candidate_hash}" != "${local_hash}" ]]; then
	mv -f "${LOCAL_CANDIDATE}" "${LOCAL}"
else
	rm -f "${LOCAL_CANDIDATE}"
fi

"${AR}" rcs "${LOCAL_ARCHIVE_CANDIDATE}" "${LOCAL}"
archive_candidate_hash="$(sha256sum "${LOCAL_ARCHIVE_CANDIDATE}" | cut -d ' ' -f 1)"
archive_hash=""
if [[ -f "${LOCAL_ARCHIVE}" ]]; then
	archive_hash="$(sha256sum "${LOCAL_ARCHIVE}" | cut -d ' ' -f 1)"
fi
if [[ "${archive_candidate_hash}" != "${archive_hash}" ]]; then
	mv -f "${LOCAL_ARCHIVE_CANDIDATE}" "${LOCAL_ARCHIVE}"
else
	rm -f "${LOCAL_ARCHIVE_CANDIDATE}"
fi
echo "Done: ${LOCAL} and ${LOCAL_ARCHIVE}"
