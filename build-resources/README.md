# THOTH/build-resources

Build-oriented source trees moved out of `THOTH/forks`.

This directory is for toolchain, compiler, ROCm, PyTorch, and low-level build
resources that support the runtime/model work in [`forks/`](../forks/README.md)
but are not themselves the primary research/runtime donor repos.

## Current Scope

- ROCm core and math sources
- Triton and related compiler/runtime layers
- PyTorch and TorchVision source trees
- auxiliary build-facing repos used for local experiments on gfx1030/gfx1031

## Documentation

- [Manifest](manifest.md) — build-resource inventory
- [Donor Assessment](../docs/research/donor-assessment.md) — notes on selected ROCm/toolchain donors
- [Fork Registry](../forks/manifest.md) — runtime and research donor registry
