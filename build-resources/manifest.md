# THOTH/build-resources Manifest

Build-resource sources separated from `THOTH/forks`.

## Tracked Submodules

| Folder | Role | Notes |
|--------|------|-------|
| **aotriton** | Triton build blocker map | gfx103x coverage gap reference for PyTorch SDPA/FlashAttention paths |
| **hip** | ROCm core runtime/compiler | Core HIP source tree |
| **rocBLAS** | ROCm math | GEMM and attention-adjacent math kernels |
| **rocm-install-on-linux** | ROCm setup | Official install scripts and packaging reference |
| **rocm-libraries** | ROCm library stack | Consolidated ROCm math/library umbrella |
| **Tensile** | Kernel generator | rocBLAS kernel-generation source |
| **TheRock** | ROCm build system | gfx103X target-family build plumbing |

## Local Build Trees

These currently exist as local nested repos or source trees rather than THOTH
submodules.

| Folder | Role | Notes |
|--------|------|-------|
| **aiter** | AMD attention/runtime support | local build-facing source tree |
| **bitsandbytes-rocm** | ROCm quant/runtime support | local build-facing source tree |
| **flash-attention** | Attention kernel source | local build-facing source tree |
| **pytorch** | PyTorch source | local build-facing source tree |
| **rocm_sdk_builder** | ROCm patch/build farm | local build-facing source tree |
| **triton** | Triton source | local build-facing source tree |
| **vision** | TorchVision source | moved from `forks/vision` |
