# PrismML Q1_0 Port — Validation Results

**Date:** 2026-04-01
**Commit:** `542476682` on `carlosfundora/llama-turboquant`
**PR:** [unixsysdev/llama-turboquant#6](https://github.com/unixsysdev/llama-turboquant/pull/6)

## Summary

Successfully ported PrismML's Q1_0 and Q1_0_G128 1-bit ternary quantization
types into the turboquant fork. Bonsai models now load and produce coherent
output.

## Type ID Resolution

| Type | PrismML ID | Turboquant ID | Block Size | Type Size |
|------|-----------|---------------|------------|-----------|
| Q1_0 | 40 | 42 | 32 | 6 bytes |
| Q1_0_G128 | 41 | 43 | 128 | 18 bytes |
| NVFP4 (unchanged) | 40 | 40 | 64 | 36 bytes |
| TQ3_0 (unchanged) | 41 | 41 | 32 | 14 bytes |

GGUF reader auto-detects PrismML files via `general.file_type` (40 or 41)
and remaps type IDs at load time.

## Test Results

### CPU (llama-turboquant fork)

| Model | Size | Type | Load | Output | Speed |
|-------|------|------|------|--------|-------|
| Bonsai-1.7B | 237 MB | Q1_0_G128 | ✅ | Coherent | 1.5 t/s (CPU) |
| Bonsai-4B | 546 MB | Q1_0_G128 | ✅ | Coherent | 0.7 t/s (CPU) |
| Bonsai-8B | 1.1 GB | Q1_0_G128 | ✅ | Coherent | 0.3 t/s (CPU) |

### GPU (PrismML native HIP build — gfx1030, ROCm 7.2)

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) |
|-------|------|--------|-------------|-------------|
| Bonsai-1.7B | 231 MiB | 1.72B | **2096.87** | **75.60** |
| Bonsai-4B | 540 MiB | 4.02B | **856.64** | **120.66** |
| Bonsai-8B | 1.07 GiB | 8.19B | **453.90** | **91.56** |

GPU speedup: **~172× over CPU** (Bonsai-4B). See [gpu-benchmark-results.md](gpu-benchmark-results.md).

### Sample Output (Bonsai-4B)

> Prompt: "The meaning of life is"
> Output: "a profound and deeply personal question that has no single, universally accepted"

## Files Modified (11 files, +282 lines)

1. `ggml/include/ggml.h` — Type enum + ftype entries
2. `ggml/src/ggml-common.h` — Block struct definitions
3. `ggml/src/ggml-quants.h` — Function declarations
4. `ggml/src/ggml-quants.c` — Quantize/dequantize implementations
5. `ggml/src/ggml.c` — type_traits, ftype mapping, quantize dispatch
6. `ggml/src/ggml-cpu/ggml-cpu.c` — CPU type traits with vec_dot
7. `ggml/src/ggml-cpu/quants.h` — vec_dot declarations
8. `ggml/src/ggml-cpu/quants.c` — vec_dot implementations + wrappers
9. `ggml/src/ggml-cpu/ops.cpp` — Switch case additions (7 locations)
10. `ggml/src/gguf.cpp` — PrismML compatibility remap shim
11. `gguf-py/gguf/constants.py` — Python enum + block sizes

## Known Limitations

- **turboquant fork**: Q1_0 has CPU-only dequantize — no GPU mat-mul kernels (MMVQ/MMQ)
- **PrismML fork**: Full GPU support (MMVQ + dequant + convert), but no TQ3_0 KV cache
- **MMQ on RDNA2**: PrismML's Q1_0 MMQ requires Turing MMA (SM≥75), falls back to cuBLAS on gfx1030 (still fast: 454-2097 t/s prompt processing due to trivial 1-bit dequant)
- **No SIMD**: Generic C vec_dot in turboquant fork (scalar loops)
- **Remap heuristic**: Depends on `general.file_type` KV metadata

## Next Steps

- [x] ~~Add HIP dequantize kernel for GPU inference~~ → Available via PrismML's native fork
- [x] ~~Benchmark GPU-offloaded Q1_0 inference~~ → 121 t/s gen on Bonsai-4B
- [ ] Port PrismML's Q1_0 GPU kernels (MMVQ/MMQ/convert) into llama-turboquant fork
- [ ] OR: Port TQ3_0 KV cache support into PrismML fork
- [ ] Test Q1_0 weights + TQ3_0 V-only KV cache combo
- [ ] Add SIMD-optimized vec_dot (AVX2/NEON)
- [ ] Rebuild Docker image with combined support
