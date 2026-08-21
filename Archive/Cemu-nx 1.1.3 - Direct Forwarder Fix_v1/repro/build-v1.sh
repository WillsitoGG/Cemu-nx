#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
BASE="$ROOT/.github/scripts/build-willsito-direct-forwarder.sh"
GENERATED=/tmp/build-cemu-v1.generated.sh

python3 - "$BASE" "$GENERATED" <<'PY'
from pathlib import Path
import sys
src=Path(sys.argv[1]).read_text()
out=Path(sys.argv[2])

src=src.replace('OUT="${OUT:-$ROOT/cemu-fix-build-output}"',
                'OUT="${OUT:-$ROOT/cemu-v1-build-output}"',1)
src=src.replace('WORK="${WORK:-/work/cemu-direct-forwarder-fix}"',
                'WORK="${WORK:-/work/cemu-direct-forwarder-v1}"',1)
src=src.replace('EXPECTED_SOURCE_BLOB="8a40edb75434fbef0ed8a854264b77ab11d049dd"',
                'EXPECTED_SOURCE_BLOB="1ab55ef775dc44fb0897f6720ffcc945d134ca1d"',1)

old='''cp "$ROOT/switch_launcher/source/main.cpp" "$CEMU/switch_launcher/source/main.cpp"\nSOURCE_BLOB="$(git -C "$CEMU" hash-object switch_launcher/source/main.cpp)"\ntest "$SOURCE_BLOB" = "$EXPECTED_SOURCE_BLOB"\ngit -C "$CEMU" diff --check\ntest "$(git -C "$CEMU" diff --name-only)" = "switch_launcher/source/main.cpp"\ngit -C "$CEMU" diff -- switch_launcher/source/main.cpp > "$OUT/Cemu-1.1.3-DirectForwarderFix-v2.patch"\ncp "$CEMU/switch_launcher/source/main.cpp" "$OUT/Cemu_main_patched.cpp"\n'''
new='''git -C "$CEMU" apply --check "$ROOT/Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/repro/Cemu-1.1.3-DirectForwarderFix-v1.patch"\ngit -C "$CEMU" apply "$ROOT/Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/repro/Cemu-1.1.3-DirectForwarderFix-v1.patch"\nSOURCE_BLOB="$(git -C "$CEMU" hash-object switch_launcher/source/main.cpp)"\ntest "$SOURCE_BLOB" = "$EXPECTED_SOURCE_BLOB"\ngit -C "$CEMU" diff --check\ntest "$(git -C "$CEMU" diff --name-only)" = "switch_launcher/source/main.cpp"\ngit -C "$CEMU" diff -- switch_launcher/source/main.cpp > "$OUT/Cemu-1.1.3-DirectForwarderFix-v1.generated.patch"\ncmp "$OUT/Cemu-1.1.3-DirectForwarderFix-v1.generated.patch" "$ROOT/Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/repro/Cemu-1.1.3-DirectForwarderFix-v1.patch"\ncp "$CEMU/switch_launcher/source/main.cpp" "$OUT/Cemu_main_patched_v1.cpp"\n'''
if old not in src:
    raise SystemExit('current-source block not found')
src=src.replace(old,new,1)

start=src.index('python3 - "$CEMU/switch_launcher/source/main.cpp" "$OUT/STATIC_TEST.txt" <<\'PY\'\n')
end=src.index("\nPY\n\npython3 - <<'PY'\n",start)+4
static='''python3 - "$CEMU/switch_launcher/source/main.cpp" "$OUT/STATIC_TEST.txt" <<'PY'\nfrom pathlib import Path\nimport sys\ns=Path(sys.argv[1]).read_text(); out=Path(sys.argv[2])\nfor marker in (\n    'silentDirectForwarder',\n    'prepareDirectForwarderGame',\n    'if(!silentDirectForwarder) startGameScan(gamePaths,true);',\n    'if(!forwarderDirectPath) renderUsbForwarderWait();',\n    'for(int ai=1; ai+1<argc; ai++) if(strcmp(argv[ai],"-g")==0)',\n):\n    assert marker in s, marker\nassert 'positionalForwarderPathEarly' not in s\nassert 'resolveDirectGameHeadless' not in s\nout.write_text(\n    'PASS exact historical v1 source blob reconstructed from upstream + archived patch\\n'\n    'PASS positional argv[1] direct-forwarder logic present\\n'\n    'PASS normal launcher and NaGaa -g parser retained\\n'\n    'PASS v2 pre-SDL headless fast path absent, as expected for v1\\n')\nPY\n'''
src=src[:start]+static+src[end:]

src=src.replace('APP_VERSION=1.1.3-v2','APP_VERSION=1.1.3',1)
src=src.replace("grep -Eq 'DisplayVersion:[[:space:]]+1\\.1\\.3-v2' \"$OUT/NRO_METADATA.txt\"",
                "grep -Eq 'DisplayVersion:[[:space:]]+1\\.1\\.3' \"$OUT/NRO_METADATA.txt\"",1)

prov_start=src.index('cat > "$OUT/PROVENANCE.txt" <<EOF\n')
prov_end=src.index('\nEOF\ncat "$OUT/REBUILT_SHA256SUMS.txt"',prov_start)+5
provenance='''cat > "$OUT/PROVENANCE.txt" <<EOF\nCemu-nx 1.1.3 – Direct Forwarder Fix_v1 historical reproducibility build\nUpstream source commit: $SOURCE_COMMIT\nExact historical source blob: $SOURCE_BLOB\nHistorical patch: Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/repro/Cemu-1.1.3-DirectForwarderFix-v1.patch\nOfficial Cemu-nx 1.1.3 NRO SHA-256: $EXPECTED_OFFICIAL_NRO_SHA256\nOfficial embedded cemu_core.nro SHA-256: $EXPECTED_CORE_SHA256\nNACP DisplayVersion: 1.1.3\nExpected historical published NRO SHA-256: ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456\nEOF\n'''
src=src[:prov_start]+provenance+src[prov_end:]

needle='cat "$OUT/REBUILT_SHA256SUMS.txt"\n'
replacement='''cat "$OUT/REBUILT_SHA256SUMS.txt"\nREBUILT_SHA="$(awk '{print $1}' "$OUT/REBUILT_SHA256SUMS.txt")"\ntest "$REBUILT_SHA" = 'ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456'\nprintf 'EXACT_MATCH\\n' > "$OUT/HISTORICAL_MATCH_STATUS.txt"\n'''
if needle not in src:
    raise SystemExit('final checksum print not found')
src=src.replace(needle,replacement,1)
out.write_text(src)
PY

bash "$GENERATED"
