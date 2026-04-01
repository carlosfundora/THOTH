# THOTH/forks Manifest

> 23 submodules — OpenCoder + TurboQuant + EAGLE + Medusa on gfx1031 (RX 6700 XT)
> See [docs/research/donor-assessment.md](../docs/research/donor-assessment.md) for detailed per-fork analysis.

## Fork Registry

| Folder | Donor Role | Purpose | License |
|--------|-----------|---------|---------|
| **llama-turboquant** | ⭐ Primary build target | TheTom's llama.cpp + TurboQuant KV cache (HIP + HSA_OVERRIDE=10.3.0). Explicitly supports gfx1030/1031/1035. Start here. | MIT |
| **turboquant_plus** | ⭐ Algorithm donor | TheTom's clean algorithm library: rotation, codebook, polar_quant, qjl, kv_cache, outlier. Best paper decomposition. | Apache-2.0 |
| **turboquant-h2o-streamingllm** | HIP kernel donor | TurboQuant 4-bit + H2O attention skipping. Full `turboquant_hip.h/cpp` AMD kernels. | Check |
| **vllm** | Serving engine (layout donor) | vLLM mainline — PR #38280 TurboQuantBackend, KV slot layout, Triton kernels. ⚠️ 0.36x throughput. | Apache-2.0 |
| **vllm-turboquant** | Serving engine (drop-in) | mitkox pre-packaged vLLM 0.18.1rc1 + TurboQuant. Easiest serving test. | Apache-2.0 |
| **sglang** | Serving engine (modular) | SGLang — PR #21617 + #21628 (AMD). Cleanest `turboquant.py` hook. 42 tests. | Apache-2.0 |
| **turboquant** | Reference (read-only) | 0xSero standalone implementation. Triton + vLLM. ⚠️ GPL-3.0 — do not copy. | GPL-3.0 |
| **turboquant-1** | Reference | Alternative/early TurboQuant fork. | Check |
| **dendrite** | Runtime architecture donor | Direct quantized-page runtime (`PageFormat::TurboQuant4Bit`). Avoids dequant-then-attend. 3.88x memory reduction. | Check |
| **EAGLE** | Speculative decoding | EAGLE-3 draft model — best-in-class replacement for Medusa. | Apache-2.0 |
| **Medusa** | Speculative decoding | Medusa multi-head speculative decoding. Current 1.5B draft. | Apache-2.0 |
| **SpecForge** | Draft model trainer | Official EAGLE draft-model trainer (works with SGLang). | Apache-2.0 |
| **ATLAS** | Long-term goal | Together.ai adaptive speculative decoding framework. | Check |
| **llama.cpp** | Reference baseline | Base llama.cpp (reference + Vulkan/HIP backend). Compare against TurboQuant. | MIT |
| **unsloth** | Training | 4-bit QLoRA training — fast 1.5B Medusa/EAGLE head training on 12 GB. | Apache-2.0 |
| **bitpolar** | KV utilities | Vector quantization & bit-packing library. | Check |
| **aotriton** | ⚠️ Blocker map | AMD Triton — no gfx103x in recent releases. PyTorch FlashAttention path blocker. | MIT |
| **hip** | ROCm core | AMD HIP runtime & compiler. Core for any TurboQuant HIP kernels. | MIT |
| **rocBLAS** | ROCm math | GEMM/attention kernels. Missing gfx1031 Tensile kernels → use override. | MIT |
| **rocm-install-on-linux** | ROCm setup | Official install scripts + patch examples for consumer GPUs. | MIT |
| **rocm-libraries** | ROCm math | Consolidated math libraries (rocBLAS, MIOpen, etc.). 13 GB. | MIT |
| **Tensile** | ROCm kernels | AMD kernel generator (used by rocBLAS). Missing gfx1031 precompiled kernels. | MIT |
| **TheRock** | ROCm build system | New open build system. Has `gfx103X-all` target plumbing. | MIT |

> **rocm_sdk_builder** is maintained outside THOTH at `/home/local/Projects/build/rocm_sdk_builder`. Tested on gfx1031, formal patch system, vLLM build flows. See [build/INDEX.md](../../build/INDEX.md).

## Auto-generated on 2026-03-31
## Project goal: Frozen 8B OpenCoder target + TurboQuant KV + adaptive EAGLE/Medusa draft on RX 6700 XT (gfx1031)
