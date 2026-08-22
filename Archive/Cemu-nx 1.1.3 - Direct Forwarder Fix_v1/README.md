# Cemu-nx 1.1.3 – Direct Forwarder Fix_v1

Historical final revision superseded by `Cemu-nx 1.1.3 – Direct Forwarder Fix v2`.

## Historical identity

- Historical release name: `Cemu-nx 1.1.3 – Direct Forwarder Fix`
- Historical tag: `cemu-nx-1.1.3-direct-forwarder-fix`
- Historical asset name: `Cemu.nro`
- Exact historical SHA-256: `ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456`
- Exact historical Git blob in the former tuning repository: `43abc5b2e776f7597b03d5d3c8407cf97471936a`
- Exact historical source blob: `1ab55ef775dc44fb0897f6720ffcc945d134ca1d`
- Upstream base: `9e8dcba0fefae6f5b98722c7505327bb4e325019`

## What is preserved here

The original historical NRO could not be recovered byte-for-byte from the remaining accessible inputs, so this directory intentionally does **not** contain a replacement `Cemu.nro` presented as authentic.

The recoverable historical source state is preserved through:

- `repro/Cemu-1.1.3-DirectForwarderFix-v1.patch`
- `repro/build-v1.sh`
- the pinned upstream commit and source/blob identities documented above

Applying the archived patch to the pinned upstream base reconstructs the exact historical source blob `1ab55ef775dc44fb0897f6720ffcc945d134ca1d`.

## Reproducibility result

A final rebuild was performed with:

- container: `devkitpro/devkita64:20260219`
- original absolute build path: `/work/cemu-direct-forwarder-fix`
- exact historical source
- official Cemu-nx 1.1.3 RomFS/core inputs

Resulting rebuild SHA-256:

`94d1e8cf5be07fe18614ec01760dca8fa047bb0c2ecb3946b4f47f5bd3a3880a`

This does not match the historical published SHA-256 `ecf28315b453617b7d8c8eff89c728f162f62aaf88814ae210f639ece7095456`.

Therefore the rebuild is **not** the historical v1 binary and must never be substituted for it. The historical SHA-256 remains the identity record; the rebuild result is retained only as reproducibility evidence in `Validation/V1_REPRODUCIBILITY.txt`.
