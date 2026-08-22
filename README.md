# Cemu-nx – WillsitoGG tuning

This fork keeps `NaGaa95/Cemu-nx` clean on `main` and stores WillsitoGG-specific tuning work on `willsito-tuning`.

## Branch model

- `main`: exact upstream tracking branch. Do not place tuning files, archives or migration helpers here.
- `fix/direct-forwarder`: clean upstream-facing source change used by PR #5.
- `willsito-tuning`: permanent tuning branch with source, reproducible validation, release notes, hashes and historical archive.

## Current tuning

**Cemu-nx 1.1.3 – Direct Forwarder Fix v2**

- Upstream base: `9e8dcba0fefae6f5b98722c7505327bb4e325019`
- Upstream-facing commit: `8e31e7d615e4f43d4e765ba9ff56fee4904f1d93`
- Tuned source: `switch_launcher/source/main.cpp`
- Exact tuned source blob: `8a40edb75434fbef0ed8a854264b77ab11d049dd`
- Hardware-tested/published NRO SHA-256: `36488988b8b814b865243c6f27258374685a0ee88a53a7cddfdee5b9842a3ece`
- Reproducibility status: **exact bit-for-bit match**. The app-specific validation rebuild produced the same SHA-256.

The positional `argv[1]` path is detected before SDL/video initialization and follows a fully headless launch path to the embedded `cemu_core.nro`. The normal launcher and NaGaa's `-g <gameKey>` behavior remain unchanged.

## Historical final revision

`Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/` preserves the recoverable history of the superseded v1 release.

The original published v1 identity is known:

- Historical tag: `cemu-nx-1.1.3-direct-forwarder-fix`
- Historical NRO SHA-256: `ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456`
- Exact historical source blob: `1ab55ef775dc44fb0897f6720ffcc945d134ca1d`

The original v1 NRO itself is not recoverable from the remaining app-specific inputs, so no replacement binary is presented as authentic. The exact historical source is reconstructible from the pinned upstream base plus the archived patch. A final reproduction attempt using the pinned `devkitpro/devkita64:20260219` environment and the original absolute build path `/work/cemu-direct-forwarder-fix` produced:

`94d1e8cf5be07fe18614ec01760dca8fa047bb0c2ecb3946b4f47f5bd3a3880`

Because that does **not** equal the historical SHA-256, the rebuild is validation evidence only and is not archived as the historical v1 binary. See `Validation/V1_REPRODUCIBILITY.txt`.

## Validation policy

Historical published hashes, current release assets and fresh rebuilds are distinct concepts:

- A rebuild may be called identical only when its SHA-256 matches the published binary exactly.
- A non-matching rebuild must never replace an unrecoverable historical binary.
- The official embedded `cemu_core.nro` must remain byte-for-byte identical to Cemu-nx 1.1.3.
- Real-hardware testing is stated only for builds actually tested by the user.

## Release policy

Only the current final WillsitoGG tuning should remain visible under Releases. Superseded final versions belong under `Archive/` with the exact recoverable source/patch material, provenance and known identities. Temporary, failed or experimental build output must not remain in the permanent branch.
