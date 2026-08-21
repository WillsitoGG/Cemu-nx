# Cemu-nx – WillsitoGG tuning

This fork keeps NaGaa95/Cemu-nx clean on `main` and stores WillsitoGG-specific tuning work on `willsito-tuning`.

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
- Historical hardware-tested/published NRO SHA-256: `36488988b8b814b865243c6f27258374685a0ee88a53a7cddfdee5b9842a3ece`

The positional `argv[1]` path is detected before SDL/video initialization and follows a fully headless launch path to the embedded `cemu_core.nro`. The normal launcher and NaGaa's `-g <gameKey>` behavior remain unchanged.

## Historical final revision

`Archive/Cemu-nx 1.1.3 - Direct Forwarder Fix_v1/` preserves the superseded v1 release. The exact historical NRO is migrated byte-for-byte from the previous tuning repository; it is not recreated or substituted by a rebuild.

## Validation policy

The Release asset and archived v1 binary are preserved exactly. Rebuilds are used only as independent reproducibility/structure checks and their hashes are recorded separately from hardware-tested/published hashes.

The official embedded `cemu_core.nro` must remain byte-for-byte identical to Cemu-nx 1.1.3.

## Release policy

Only the current final WillsitoGG tuning should remain visible under Releases. Superseded final versions belong under `Archive/` with provenance and checksums. Temporary, failed or experimental build output must not remain in the permanent branch.
