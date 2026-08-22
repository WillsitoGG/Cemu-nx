# AGENTS.md

## Scope

These instructions apply to the WillsitoGG tuning work in this fork.

## Branches

- Keep `main` identical to `NaGaa95/Cemu-nx` unless explicitly synchronizing with upstream.
- Keep upstream contribution branches minimal and source-only.
- Put custom documentation, validation, archive material, scripts and release metadata on `willsito-tuning`.

## Exact-source rule

The current validated Direct Forwarder Fix v2 source is `switch_launcher/source/main.cpp` with Git blob:

`8a40edb75434fbef0ed8a854264b77ab11d049dd`

Do not refactor or alter that source while claiming to reproduce the tested tuning. Any future source change must be treated as a new revision and validated separately.

## Current upstream base

`9e8dcba0fefae6f5b98722c7505327bb4e325019`

## Binary provenance

- Current hardware-tested/published v2 NRO SHA-256: `36488988b8b814b865243c6f27258374685a0ee88a53a7cddfdee5b9842a3ece`.
- Historical v1 published NRO SHA-256: `ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456`.
- Historical v1 exact source blob: `1ab55ef775dc44fb0897f6720ffcc945d134ca1d`.
- Historical v1 final reproduction SHA-256: `94d1e8cf5be07fe18614ec01760dca8fa047bb0c2ecb3946b4f47f5bd3a3880a`.
- The v1 reproduction is **not** byte-identical to the published v1 binary and must never be stored, released or described as that historical binary.
- Never replace a historical identity with a fresh rebuild unless the SHA-256 proves exact byte identity.
- Fresh rebuilds are validation artifacts and must have their own hashes.

## Embedded core rule

The official Cemu-nx 1.1.3 `cemu_core.nro` must remain byte-for-byte identical. Expected SHA-256:

`4e7b0aaf6f4f33c55f2dd4af5f18f089667d319a37f422297dce0a647cf074e1`

## Historical archive

Superseded final releases belong under `Archive/`. Preserve exact recoverable binaries, exact source/patch provenance and SHA-256 identities. Never fabricate an unrecoverable historical binary.

For Cemu v1 specifically, preserve the exact source patch/reproduction recipe and the known historical SHA-256, but do not add a `Cemu.nro` unless a future recovery is proven byte-identical to `ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456`.

## Releases

Only the current final WillsitoGG tuning should be visible in Releases. The user-facing asset is `Cemu.nro`; validation files belong in the repository, not as extra release assets unless explicitly requested.

## Validation language

Distinguish:

- static/automated validation,
- reproducibility rebuilds,
- historical published hashes,
- real Nintendo Switch hardware testing.

Never claim hardware testing unless the user actually performed it.

## Cleanliness

Do not keep temporary workflows, trigger files, logs or discarded build directories in the permanent branch.
