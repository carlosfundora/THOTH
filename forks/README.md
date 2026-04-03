# THOTH/forks – Runtime And Research Donors

Personal research fork collection for a full ATLAS-style speculative system with TurboQuant KV cache on consumer AMD hardware.

## Current Status (2026-03-31)

**No turnkey gfx1031 + TurboQuant setup exists.** But the missing pieces are now visible:
- Real AMD HIP kernels exist (TheTom fork, peva3 H2O fork)
- vLLM and SGLang both have active ROCm TurboQuant branches (community forks merged in last 48h)
- TheTom proved TurboQuant works on AMD HIP (RX 9070 XT benchmarks: +2 t/s, 25% less KV memory)
- Same HIP code path is what gfx1031 override piggybacks on

## Attack Order

1. **HIP llama.cpp** → `forks/llama-turboquant` + `HSA_OVERRIDE=10.3.0` (shortest path)
2. **Algorithm validation** → `forks/turboquant_plus` + scos-lab on CPU (verify math independently)
3. **SGLang AMD branch** → `forks/sglang` PR #21628 (cleanest modular port)
4. **vLLM** → `forks/vllm-turboquant` (serving, but 0.36x throughput penalty)

See [docs/attack-plan.md](../docs/attack-plan.md) for full experiment definitions.

## Purpose
- Frozen 8B target (OpenCoder) + TurboQuant KV
- Adaptive 1.5B draft (Medusa → EAGLE-3)
- RadixAttention + SGLang / vLLM / llama.cpp paths
- All patches and experiments stay local

## Documentation
- [Attack Plan](../docs/attack-plan.md) — ordered experiment list
- [Ecosystem Landscape](../docs/research/turboquant-gfx1031-landscape.md) — what changed, PR statuses
- [Donor Assessment](../docs/research/donor-assessment.md) — per-fork shopping list
- [gfx1031 Compatibility](../docs/research/gfx1031-rocm-compat.md) — override hacks, breakage patterns
- [Manifest](manifest.md) — full fork registry with donor roles
- [Build Resources](../build-resources/README.md) — relocated toolchain, ROCm, PyTorch, and compiler sources

## Build Resource Split

`THOTH/forks` now holds runtime and research donors.

Shared build sources that used to be mixed into `forks/` have been moved to
[`THOTH/build-resources`](../build-resources/README.md), including ROCm,
PyTorch, Triton, TorchVision, and compiler-oriented sources.

External system-level build tooling still lives under `/home/local/Projects/build`.

- `build-resources/` — local source trees for build-oriented repos
- `/home/local/Projects/build/bin` — system-facing build tools
- `/home/local/Projects/build/INDEX.md` — external build catalog

## Quick Links
- Primary build target: `llama-turboquant` (HIP + HSA_OVERRIDE=10.3.0)
- Docker environment: `Projects/docker/thoth/`
- Patch-series tool: `/home/local/Projects/build/bin/quilt`

Last updated: 2026-03-31
