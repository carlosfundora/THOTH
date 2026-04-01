# THOTH/forks – OpenCoder + TurboQuant + EAGLE + Medusa on gfx1031 (RX 6700 XT)

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

## Shared Build Infrastructure

THOTH keeps research forks under `THOTH/forks`, but shared build infrastructure lives under `/home/local/Projects/build`.

- `rocm_sdk_builder` at `/home/local/Projects/build/rocm_sdk_builder` (tested on gfx1031)
- System-facing build tools at `/home/local/Projects/build/bin`
- Canonical catalog at `/home/local/Projects/build/INDEX.md`

## Quick Links
- Primary build target: `llama-turboquant` (HIP + HSA_OVERRIDE=10.3.0)
- Docker environment: `Projects/docker/thoth/`
- Patch-series tool: `/home/local/Projects/build/bin/quilt`

Last updated: 2026-03-31
