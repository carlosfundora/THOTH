# THOTH/forks – OpenCoder + TurboQuant + EAGLE + Medusa on gfx1031 (RX 6700 XT)

Personal research fork collection for a full ATLAS-style speculative system with TurboQuant KV cache on consumer AMD hardware.

## Purpose
- Frozen 8B target (OpenCoder) + TurboQuant KV
- Adaptive 1.5B draft (Medusa → EAGLE-3)
- RadixAttention + SGLang / vLLM / llama.cpp paths
- All patches and experiments stay local

## Quick links
- Primary build target: `llama-turboquant` (HIP + HSA_OVERRIDE=10.3.0)
- Next: SGLang with TurboQuant + EAGLE
- Shared build hub: `/home/local/Projects/build`
- Patch-series tool: `/home/local/Projects/build/bin/quilt`

## Shared build infrastructure

THOTH keeps research forks under `THOTH/forks`, but shared build infrastructure now lives under `/home/local/Projects/build`.

- `rocm_sdk_builder` is maintained at `/home/local/Projects/build/rocm_sdk_builder`
- system-facing build tools are exposed through `/home/local/Projects/build/bin`
- the canonical catalog for shared build assets is `/home/local/Projects/build/INDEX.md`

Last updated: 2026-03-31
