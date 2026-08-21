# Cemu-nx 1.1.3 – Direct Forwarder Fix v2

Keeps Cemu-nx 1.1.3 and adds a fully headless positional NSP-forwarder path.

## What changes

- Detects a positional `argv[1]` game path before SDL/video initialization.
- Resolves title identity/configuration and prepares the normal Cemu handoff without creating the launcher UI.
- Keeps first-run embedded-core extraction headless.
- Keeps USB direct-path initialization and bounded retry headless.
- Preserves the normal launcher and NaGaa's built-in `-g <gameKey>` behavior.
- Preserves the official embedded `cemu_core.nro` byte-for-byte.

## Structural limit

Cemu-nx still performs one executable handoff from the launcher NRO to `cemu_core.nro`; this is part of the existing architecture.

## Validation

The release asset published by this fork is the exact previously hardware-tested/published v2 `Cemu.nro`, SHA-256:

`36488988b8b814b865243c6f27258374685a0ee88a53a7cddfdee5b9842a3ece`

Reproducibility rebuild hashes are recorded separately under `Validation/` and are not presented as the same binary.
