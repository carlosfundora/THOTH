# THOTH/forks Manifest (full list)

| Folder                        | Purpose |
|-------------------------------|---------|
| aotriton                      | AMD version of Triton (kernel compiler used by vLLM/SGLang TurboQuant PRs) |
| ATLAS                         | Together.ai ATLAS adaptive speculative decoding framework (our long-term goal) |
| bitpolar                      | Vector quantization & bit-packing library (KV cache utilities) |
| dendrite                      | Direct quantized-page runtime (avoids dequantize-then-attend overhead) |
| EAGLE                         | EAGLE-3 speculative decoding (best-in-class draft model replacement for Medusa) |
| hip                           | AMD HIP runtime & compiler (core for any TurboQuant HIP kernels) |
| llama.cpp                     | Base llama.cpp (reference + Vulkan/HIP backend) |
| llama-turboquant              | **Primary build target** — TheTom's llama.cpp + native TurboQuant KV cache (HIP + HSA_OVERRIDE=10.3.0) |
| Medusa                        | FasterDecoding Medusa multi-head speculative decoding (current 1.5B draft) |
| rocBLAS                       | AMD rocBLAS library (GEMM/attention kernels) |
| rocm-install-on-linux         | Official ROCm install scripts + patch examples for consumer GPUs |
| rocm-libraries                | Consolidated ROCm math libraries (rocBLAS, MIOpen, etc.) |
| rocm_sdk_builder              | lamikr's ROCm SDK builder (patch farm + gfx1031-tested builds) |
| sglang                        | SGLang inference engine (RadixAttention + TurboQuant PR + EAGLE support) |
| SpecForge                     | Official EAGLE draft-model trainer (works with SGLang) |
| Tensile                       | AMD kernel generator (used by rocBLAS for gfx1031) |
| TheRock                       | AMD's new open ROCm build system (gfx103x target plumbing) |
| turboquant                    | 0xSero standalone TurboQuant reference implementation |
| turboquant-1                  | Alternative/early TurboQuant fork |
| turboquant-h2o-streamingllm   | TurboQuant + H2O attention skipping (HIP kernels) |
| turboquant_plus               | TheTom's clean algorithm library (rotation, codebook, outlier, QJL, etc.) |
| unsloth                       | Unsloth 4-bit QLoRA training (fast 1.5B Medusa/EAGLE head training on 12 GB) |
| vllm                          | vLLM inference server (TurboQuant PR integration target) |
| vllm-turboquant               | Community vLLM fork with TurboQuant already merged |

## Auto-generated on $(date)
## Project goal: Frozen 8B OpenCoder target + TurboQuant KV + adaptive EAGLE/Medusa draft on RX 6700 XT (gfx1031)
