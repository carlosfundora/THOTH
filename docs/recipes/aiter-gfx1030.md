# AITER Build Recipe (gfx1030)

> **Target Hardware**: AMD Radeon RX 6700 XT (*gfx1030*)
> **ROCm Version**: 7.2.26015
> **Status**: Successfully Built & Verified

## Overview
AITER (AMD AI Tensor Engine) provides optimized kernels for LLM attention and quantization. Standard builds lack `gfx1030` support, requiring manual patches to the JIT engine.

## Build Recipe

### 1. Prerequisites
- `hipcc`, `rocblas`, `hipblas` (ROCm 7.x)
- `python 3.12`
- `.venv-pytorch-rocm`

### 2. Implementation Steps
1. **Clone**: `git clone https://github.com/Rockywei1/aiter.git`
2. **Patch Architecture Validation**:
   - `aiter/jit/utils/chip_info.py`: Add `18: "gfx1030"` to `GFX_MAP` and map to `RDNA2-RX6700XT`.
   - `aiter/jit/core.py`: Add `gfx1030` to `allowed_archs`.
3. **Compile**:
   ```bash
   export HSA_OVERRIDE_GFX_VERSION=10.3.0
   pip install -v -e .
   ```

## Build Card

| Property | Value |
| :--- | :--- |
| **Component** | AITER (Attention / Quantization Kernels) |
| **Commit ID** | `f6a4b1c` (approx) |
| **Arch Support** | gfx1030 (Patched) |
| **Performance** | Up to 14.3s for specific JIT module build |
| **Venv** | .venv-pytorch-rocm |
| **Last Updated** | 2026-03-15 |
