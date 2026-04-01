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

| Model | Size | Type | Load | Output | Speed |
|-------|------|------|------|--------|-------|
| Bonsai-4B | 546 MB | Q1_0_G128 | ✅ | Coherent | 0.7 t/s (CPU) |
| Bonsai-8B | 1.1 GB | Q1_0_G128 | ✅ | Coherent | 0.3 t/s (CPU) |
| Bonsai-1.7B | 208 MB | — | ❌ | Corrupt GGUF | N/A |

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

- **CPU-only**: No HIP/CUDA dequantize kernels → no GPU offload
- **No SIMD**: Generic C vec_dot (scalar loops)
- **Bonsai-1.7B**: File is independently corrupt (bad GGUF structure)
- **Remap heuristic**: Depends on `general.file_type` KV metadata

## Next Steps

- [ ] Add HIP dequantize kernel for GPU inference
- [ ] Add SIMD-optimized vec_dot (AVX2/NEON)
- [ ] Rebuild Docker image with Q1_0 support
- [ ] Benchmark GPU-offloaded Q1_0 inference
