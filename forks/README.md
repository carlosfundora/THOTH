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
- Patches go in a `patches/` folder (use quilt)

Last updated: $(date)
