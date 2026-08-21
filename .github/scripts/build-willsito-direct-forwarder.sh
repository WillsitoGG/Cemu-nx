#!/usr/bin/env bash
set -euo pipefail

export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
export DEVKITA64="${DEVKITA64:-$DEVKITPRO/devkitA64}"
export PATH="$DEVKITA64/bin:$DEVKITPRO/tools/bin:$PATH"
export PKG_CONFIG_PATH="$DEVKITPRO/portlibs/switch/lib/pkgconfig"

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
OUT="${OUT:-$ROOT/cemu-fix-build-output}"
WORK="${WORK:-/work/cemu-direct-forwarder-fix}"
CEMU="$WORK/Cemu-nx"
SOURCE_COMMIT="9e8dcba0fefae6f5b98722c7505327bb4e325019"
EXPECTED_SOURCE_BLOB="8a40edb75434fbef0ed8a854264b77ab11d049dd"
EXPECTED_OFFICIAL_NRO_SHA256="638cf4832dfd20ec5fe5783faabfd19692904323f670c3fb318715b82c90d3d0"
EXPECTED_CORE_SHA256="4e7b0aaf6f4f33c55f2dd4af5f18f089667d319a37f422297dce0a647cf074e1"

rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"

command -v aarch64-none-elf-g++
command -v elf2nro
command -v nacptool
command -v cmake
command -v ninja
command -v python3

test -f "$DEVKITPRO/portlibs/switch/lib/libGLESv2.a"
test -f "$DEVKITPRO/portlibs/switch/lib/libzstd.a"
test -f "$DEVKITPRO/portlibs/switch/lib/libturbojpeg.a"

git clone --recursive --depth 1 --branch 1.1.3 https://github.com/NaGaa95/Cemu-nx.git "$CEMU"
git -C "$CEMU" submodule update --init --recursive
test "$(git -C "$CEMU" rev-parse HEAD)" = "$SOURCE_COMMIT"

cp "$ROOT/switch_launcher/source/main.cpp" "$CEMU/switch_launcher/source/main.cpp"
SOURCE_BLOB="$(git -C "$CEMU" hash-object switch_launcher/source/main.cpp)"
test "$SOURCE_BLOB" = "$EXPECTED_SOURCE_BLOB"
git -C "$CEMU" diff --check
test "$(git -C "$CEMU" diff --name-only)" = "switch_launcher/source/main.cpp"
git -C "$CEMU" diff -- switch_launcher/source/main.cpp > "$OUT/Cemu-1.1.3-DirectForwarderFix-v2.patch"
cp "$CEMU/switch_launcher/source/main.cpp" "$OUT/Cemu_main_patched.cpp"

python3 - "$CEMU/switch_launcher/source/main.cpp" "$OUT/STATIC_TEST.txt" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); out=Path(sys.argv[2]); s=p.read_text()
main=s.index('int main(int argc, char **argv)')
early=s.index('if(!positionalForwarderPathEarly.empty())',main)
sdl=s.index('SDL_Init(SDL_INIT_VIDEO|SDL_INIT_GAMECONTROLLER|SDL_INIT_AUDIO)',main)
window=s.index('SDL_CreateWindow("Cemu"',main)
end=s.index('  SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS,"1");',early)
segment=s[early:end]
assert main < early < sdl < window
for forbidden in ('SDL_Init(', 'SDL_CreateWindow(', 'SDL_CreateRenderer(', 'TTF_Init(', 'IMG_Init(',
                  'startCoverDecodeWorker(', 'startGameScan(', 'modalMessageStatic(', 'renderGrid('):
    assert forbidden not in segment, forbidden
assert 'envSetNextLoad(EMU_NRO_DST,EMU_NRO_DST)' in segment
assert 'for(int ai=1; ai+1<argc; ai++) if(strcmp(argv[ai],"-g")==0)' in s[end:]
ensure=s.index('static bool ensureEmu()')
progress=s.index('drawSetupProgress(pct, "Preparing emulator...")',ensure)
guard=s.rfind('if(g_sdlReady){',ensure,progress)
assert guard >= ensure
for marker in ('positionalForwarderPathEarly','resolveDirectGameHeadless','silentDirectForwarder',
               'prepareDirectForwarderGame','if(!forwarderDirectPath) renderUsbForwarderWait();'):
    assert marker in s, marker
out.write_text(
    'PASS: positional argv[1] branches before SDL/video initialization\n'
    'PASS: headless branch contains no launcher UI initialization/render calls\n'
    'PASS: first-run core extraction cannot render Preparing emulator before SDL\n'
    'PASS: headless branch writes handoff and arms cemu_core.nro chainload\n'
    'PASS: normal launcher and NaGaa -g parser remain after the headless branch\n')
PY

python3 - <<'PY'
import hashlib, json, pathlib, urllib.request, zipfile
expected='638cf4832dfd20ec5fe5783faabfd19692904323f670c3fb318715b82c90d3d0'
headers={'Accept':'application/vnd.github+json','User-Agent':'willsito-cemu-builder'}
req=urllib.request.Request('https://api.github.com/repos/NaGaa95/Cemu-nx/releases/tags/1.1.3',headers=headers)
with urllib.request.urlopen(req) as r: rel=json.load(r)
if rel.get('tag_name')!='1.1.3': raise RuntimeError('Unexpected Cemu release tag')
root=pathlib.Path('/work/cemu-direct-forwarder-fix/release'); root.mkdir(parents=True,exist_ok=True)
for asset in rel.get('assets',[]):
    target=root/asset['name']
    q=urllib.request.Request(asset['browser_download_url'],headers={'User-Agent':'willsito-cemu-builder'})
    with urllib.request.urlopen(q) as src, target.open('wb') as dst:
        while True:
            block=src.read(1024*1024)
            if not block: break
            dst.write(block)
    if target.suffix.lower()=='.zip':
        try:
            with zipfile.ZipFile(target) as z:z.extractall(root/(target.stem+'_unpacked'))
        except zipfile.BadZipFile: pass
candidates=[p for p in root.rglob('*') if p.is_file() and p.suffix.lower()=='.nro']
if not candidates: raise RuntimeError('No NRO found in Cemu-nx 1.1.3 release')
candidates.sort(key=lambda p:(p.name.lower()!='cemu.nro',len(str(p))))
chosen=candidates[0]
data=chosen.read_bytes(); actual=hashlib.sha256(data).hexdigest()
if actual != expected: raise RuntimeError(f'Official NRO SHA mismatch: {actual}')
pathlib.Path('/work/cemu-direct-forwarder-fix/Cemu_official.nro').write_bytes(data)
pathlib.Path('/work/cemu-direct-forwarder-fix/official-release.txt').write_text(
    f"tag={rel.get('tag_name')}\nname={rel.get('name')}\nasset={chosen.name}\npublished_at={rel.get('published_at')}\n")
PY
cp "$WORK/official-release.txt" "$OUT/OFFICIAL_RELEASE.txt"
printf '%s  Cemu_official_1.1.3.nro\n' "$EXPECTED_OFFICIAL_NRO_SHA256" > "$OUT/OFFICIAL_NRO_SHA256.txt"

git clone --recursive --depth 1 --branch development-tip https://github.com/jakcron/nstool.git "$WORK/nstool"
cd "$WORK/nstool"
git submodule update --init --recursive
make deps -j2
make -j2
NSTOOL="$(find "$WORK/nstool" -type f -name nstool -perm -111 -print -quit)"
test -x "$NSTOOL"
mkdir -p "$WORK/official_romfs"
"$NSTOOL" -x "$WORK/official_romfs" "$WORK/Cemu_official.nro"
test -s "$WORK/official_romfs/emu/cemu_core.nro"
OFFICIAL_CORE="$(sha256sum "$WORK/official_romfs/emu/cemu_core.nro" | awk '{print $1}')"
test "$OFFICIAL_CORE" = "$EXPECTED_CORE_SHA256"
printf '%s  cemu_core.nro\n' "$OFFICIAL_CORE" > "$OUT/OFFICIAL_CORE_SHA256.txt"

rm -rf "$CEMU/switch_launcher/romfs"
mkdir -p "$CEMU/switch_launcher/romfs"
cp -a "$WORK/official_romfs/." "$CEMU/switch_launcher/romfs/"

mkdir -p "$WORK/launcher-deps"
cat > "$WORK/launcher-deps/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.22)
project(CemuLauncherDependencies LANGUAGES C CXX)
include(FetchContent)
set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG" CACHE STRING "" FORCE)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(ENABLE_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ENABLE_LIBKRB5 OFF CACHE BOOL "" FORCE)
set(ENABLE_GSSAPI OFF CACHE BOOL "" FORCE)
set(FETCHCONTENT_BASE_DIR "/work/cemu-direct-forwarder-fix/Cemu-nx/build_switch/_deps")
FetchContent_Declare(libsmb2
  GIT_REPOSITORY https://github.com/ITotalJustice/libsmb2.git
  GIT_TAG 867beea093f2863dfddea01945204f724afd6c45)
FetchContent_MakeAvailable(libsmb2)
target_compile_options(smb2 PRIVATE -UNEED_READV -UNEED_WRITEV)
target_compile_definitions(smb2 PRIVATE AES128_ECB_encrypt=smb2_AES128_ECB_encrypt)
set(USBHSFS_GPL OFF CACHE BOOL "" FORCE)
set(USBHSFS_NTFS OFF CACHE BOOL "" FORCE)
set(USBHSFS_EXT4 OFF CACHE BOOL "" FORCE)
set(USBHSFS_SXOS_DISABLE ON CACHE BOOL "" FORCE)
set(USBHSFS_EXAMPLES OFF CACHE BOOL "" FORCE)
set(_pinned 625269b7725a6e2a3f2724e8d45b602c1b20ead5)
FetchContent_Declare(libusbhsfs
  GIT_REPOSITORY https://github.com/ITotalJustice/libusbhsfs.git
  GIT_TAG ${_pinned})
FetchContent_MakeAvailable(libusbhsfs)
find_package(Git REQUIRED)
set(_uasp "/work/cemu-direct-forwarder-fix/Cemu-nx/dist/switch/libusbhsfs")
set(_patches
  "${_uasp}/0001-add-uasp-transport-hooks.patch"
  "${_uasp}/0002-fallback-to-bot-interface.patch"
  "${_uasp}/0003-cleanup-after-uasp-reset.patch")
foreach(_patch IN LISTS _patches)
  execute_process(COMMAND "${GIT_EXECUTABLE}" -c "safe.directory=${libusbhsfs_SOURCE_DIR}" apply --ignore-space-change --check "${_patch}"
    WORKING_DIRECTORY "${libusbhsfs_SOURCE_DIR}" RESULT_VARIABLE _check OUTPUT_QUIET ERROR_QUIET)
  if(_check EQUAL 0)
    execute_process(COMMAND "${GIT_EXECUTABLE}" -c "safe.directory=${libusbhsfs_SOURCE_DIR}" apply --ignore-space-change "${_patch}"
      WORKING_DIRECTORY "${libusbhsfs_SOURCE_DIR}" RESULT_VARIABLE _apply)
    if(NOT _apply EQUAL 0)
      message(FATAL_ERROR "Failed to apply ${_patch}")
    endif()
  else()
    execute_process(COMMAND "${GIT_EXECUTABLE}" -c "safe.directory=${libusbhsfs_SOURCE_DIR}" apply --ignore-space-change --reverse --check "${_patch}"
      WORKING_DIRECTORY "${libusbhsfs_SOURCE_DIR}" RESULT_VARIABLE _reverse OUTPUT_QUIET ERROR_QUIET)
    if(NOT _reverse EQUAL 0)
      message(FATAL_ERROR "Unexpected libusbhsfs source for ${_patch}")
    endif()
  endif()
endforeach()
target_sources(libusbhsfs PRIVATE "${_uasp}/usbhsfs_uasp.c" "${_uasp}/usbhsfs_uasp.h")
target_include_directories(libusbhsfs PRIVATE "${_uasp}" "${libusbhsfs_SOURCE_DIR}/source")
target_compile_definitions(libusbhsfs PRIVATE get_fattime=usbhsfs_get_fattime)
CMAKE
cmake -S "$WORK/launcher-deps" -B "$WORK/launcher-deps/build" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" -DCMAKE_BUILD_TYPE=Release
cmake --build "$WORK/launcher-deps/build" --parallel 2

test -s "$CEMU/build_switch/_deps/libsmb2-build/lib/libsmb2.a"
test -s "$CEMU/build_switch/_deps/libusbhsfs-build/liblibusbhsfs.a"

cd "$CEMU"
bash dist/switch/deps/prepare_zarchive.sh
cmake -S dependencies/ZArchive -B build_switch/dependencies/ZArchive -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" -DCMAKE_BUILD_TYPE=Release
cmake --build build_switch/dependencies/ZArchive --parallel 2 --target zarchive
test -s "$CEMU/build_switch/dependencies/ZArchive/libzarchive.a"

cd "$CEMU/switch_launcher"
make clean
make -j2 LAUNCHER_MESA20_ROOT="$DEVKITPRO/portlibs/switch" RELEASE_VERSION=1.1.3 APP_VERSION=1.1.3-v2
test -s cemu.nro
cp cemu.nro "$OUT/Cemu.nro"

python3 - "$OUT/Cemu.nro" <<'PY'
from pathlib import Path
import sys
data=Path(sys.argv[1]).read_bytes()[:0x20]
if len(data)<0x14 or data[0x10:0x14] != b'NRO0': raise SystemExit('NRO0 magic missing')
PY
"$NSTOOL" -v "$OUT/Cemu.nro" > "$OUT/NRO_METADATA.txt"
"$NSTOOL" --fstree "$OUT/Cemu.nro" > "$OUT/ROMFS_TREE.txt"
grep -Eq 'DisplayVersion:[[:space:]]+1\.1\.3-v2' "$OUT/NRO_METADATA.txt"
grep -q 'cemu_core.nro' "$OUT/ROMFS_TREE.txt"

mkdir -p "$WORK/final_romfs"
"$NSTOOL" -x "$WORK/final_romfs" "$OUT/Cemu.nro"
test -s "$WORK/final_romfs/emu/cemu_core.nro"
FINAL_CORE="$(sha256sum "$WORK/final_romfs/emu/cemu_core.nro" | awk '{print $1}')"
test "$FINAL_CORE" = "$EXPECTED_CORE_SHA256"
cat > "$OUT/CORE_COMPARE.txt" <<EOF
PASS: official embedded cemu_core.nro is byte-for-byte preserved.
official_sha256=$OFFICIAL_CORE
rebuilt_sha256=$FINAL_CORE
EOF

(cd "$OUT" && sha256sum Cemu.nro > REBUILT_SHA256SUMS.txt)
cat > "$OUT/PROVENANCE.txt" <<EOF
Cemu-nx 1.1.3 – Direct Forwarder Fix v2 reproducibility build
Upstream source commit: $SOURCE_COMMIT
Exact tuned source blob: $SOURCE_BLOB
Custom tracked-source diff: switch_launcher/source/main.cpp only
Official Cemu-nx 1.1.3 NRO SHA-256: $EXPECTED_OFFICIAL_NRO_SHA256
Official embedded cemu_core.nro SHA-256: $EXPECTED_CORE_SHA256
NACP DisplayVersion: 1.1.3-v2
Normal launcher: unchanged by the direct-forwarder path
NaGaa -g <gameKey>: retained
Important: this rebuild is validation only; the published app-specific Release preserves the previously hardware-tested NRO byte-for-byte.
EOF
cat "$OUT/REBUILT_SHA256SUMS.txt"
