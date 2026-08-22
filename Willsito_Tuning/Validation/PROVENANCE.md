# Cemu-nx 1.1.3 – Direct Forwarder Fix v2

- Upstream base commit: `9e8dcba0fefae6f5b98722c7505327bb4e325019`.
- Custom source: `switch_launcher/source/main.cpp` in this fork's `main`.
- Positional `argv[1]` is detected before SDL/video initialization and uses a headless preparation path.
- Title identity, per-game configuration and launch handoff are prepared without first creating the normal launcher window/grid.
- Normal launcher startup and NaGaa's `-g <gameKey>` mechanism remain available.
- Official Cemu-nx 1.1.3 NRO SHA-256: `638cf4832dfd20ec5fe5783faabfd19692904323f670c3fb318715b82c90d3d0`.
- Official embedded `cemu_core.nro` SHA-256: `4e7b0aaf6f4f33c55f2dd4af5f18f089667d319a37f422297dce0a647cf074e1`.
- Final embedded `cemu_core.nro` was validated byte-for-byte identical to that official core.
- Expected published custom NRO SHA-256: `36488988b8b814b865243c6f27258374685a0ee88a53a7cddfdee5b9842a3ece`.

The resulting behavior was previously manually validated on real Nintendo Switch hardware with NSP forwarders.
