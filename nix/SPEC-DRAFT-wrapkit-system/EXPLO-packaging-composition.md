# packaging-composition — exploration

## Findings

- The target shape of `mkWrapkitBin` is a single wrapped **bin**.
- Package/multi-bin composition is outside that target shape.
- The wrapped-drv generator never uses `replaceBinsInPkg`/`copyFromPkg` because only one binary is generated.

## Design crux

How is the single-bin drv composed into a package (bins + config dirs) — a separate `mkWrapkitPkg`, or the toolkit's job?

## Open threads

- Is composition a separate `mkWrapkitPkg`, or does each toolkit assemble its own package from the wrapped bin?
