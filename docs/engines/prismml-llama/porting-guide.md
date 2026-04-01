# PrismML llama.cpp — Fork Analysis & 1-Bit Porting Guide

**Date:** 2025-07-14
**Fork:** `/home/local/Projects/forks/prismml-llama.cpp`
**Upstream:** PrismML/llama.cpp (tag `prism-b8194-1179bfc`)
**Base:** Older llama.cpp snapshot (pre-TQ3_0)

---

## Summary

PrismML's fork adds **two custom 1-bit quantization types** (`Q1_0` and `Q1_0_g128`) that collide
with turboquant's type IDs 40-41 (`NVFP4` and `TQ3_0`). This is the sole reason Bonsai GGUF
models fail to load in our turboquant binary.

The fork has **no other unique features** — everything else (bitnet arch, qwen3, Vulkan source,
EAGLE) also exists in turboquant's newer codebase. The only value is the Q1_0 quantization code.

---

## Type ID Conflict (The Core Problem)

| Type ID | PrismML | Turboquant | Conflict? |
|---------|---------|-----------|-----------|
| 34 | TQ1_0 | TQ1_0 | ✅ Same |
| 35 | TQ2_0 | TQ2_0 | ✅ Same |
| 39 | MXFP4 | MXFP4 | ✅ Same |
| **40** | **Q1_0** | **NVFP4** | ❌ **CONFLICT** |
| **41** | **Q1_0_g128** | **TQ3_0** | ❌ **CONFLICT** |

---

## Code to Port (6 files)

### 1. `ggml/include/ggml.h` — Add new type IDs

```c
// After existing types:
GGML_TYPE_TQ3_0   = 41,   // turboquant (keep)
// Add PrismML 1-bit types with non-conflicting IDs:
GGML_TYPE_Q1_0      = 42,
GGML_TYPE_Q1_0_g128 = 43,
GGML_TYPE_COUNT     = 44,  // bump
```

### 2. `ggml/src/ggml-common.h` — Add block structs

```c
#define QK1_0 32
typedef struct {
    ggml_half d;            // scale (2 bytes)
    uint8_t qs[QK1_0 / 8]; // 1 bit per element (4 bytes)
} block_q1_0;               // 6 bytes total

#define QK1_0_g128 128
typedef struct {
    ggml_half d;                  // scale (2 bytes)
    uint8_t qs[QK1_0_g128 / 8];  // 1 bit per element (16 bytes)
} block_q1_0_g128;                // 18 bytes total
```

### 3. `ggml/src/ggml.c` — Add type traits

```c
[GGML_TYPE_Q1_0] = {
    .type_name      = "q1_0",
    .blck_size      = QK1_0,                  // 32
    .type_size      = sizeof(block_q1_0),     // 6
    .is_quantized   = true,
    .to_float       = dequantize_row_q1_0,
    .from_float_ref = quantize_row_q1_0_ref,
},
[GGML_TYPE_Q1_0_g128] = {
    .type_name      = "q1_0_g128",
    .blck_size      = QK1_0_g128,                  // 128
    .type_size      = sizeof(block_q1_0_g128),     // 18
    .is_quantized   = true,
    .to_float       = dequantize_row_q1_0_g128,
    .from_float_ref = quantize_row_q1_0_g128_ref,
},
```

### 4. `ggml/src/ggml-quants.c` — Port quantize/dequantize kernels

**Q1_0 algorithm** (ternary quantization):
- Compute scale = mean(abs(values)) per block
- Encode each element as 1 bit: sign(value)
- Dequantize: bit=1 → +scale, bit=0 → -scale

```c
// Dequantize Q1_0 (32-element blocks)
void dequantize_row_q1_0(const block_q1_0 * x, float * y, int64_t k) {
    for (int i = 0; i < k / QK1_0; i++) {
        float d = GGML_FP16_TO_FP32(x[i].d);
        for (int j = 0; j < QK1_0; j++) {
            int bit = (x[i].qs[j / 8] >> (j % 8)) & 1;
            y[i * QK1_0 + j] = bit ? d : -d;
        }
    }
}

// Same pattern for Q1_0_g128 with 128-element blocks
```

### 5. `ggml/src/gguf.cpp` — Add GGUF type ID remapping

```c
// In gguf_init_from_file_ptr(), after reading tensor type:
// Remap PrismML type IDs to our IDs
if (tensor_type == 40) tensor_type = GGML_TYPE_Q1_0;       // PrismML's Q1_0
if (tensor_type == 41) tensor_type = GGML_TYPE_Q1_0_g128;  // PrismML's Q1_0_g128
```

### 6. `gguf-py/gguf/constants.py` — Add Python file types

```python
MOSTLY_Q1_0       = 42
MOSTLY_Q1_0_g128  = 43
```

---

## GGUF Remapping Strategy

Since PrismML GGUFs encode type IDs 40/41, we need a load-time remap.
The cleanest approach: detect PrismML-origin files by checking metadata:
- PrismML files have `general.architecture: qwen3` + 1-bit tensor sizes
- Or check if any tensor has type 40/41 AND the computed offset doesn't match NVFP4/TQ3_0 expectations

Simpler fallback: always remap 40→42 and 41→43 when:
```c
type_size_on_disk != expected_type_size_for_type_40
```

---

## Alternative: Re-export with Our Converter

If porting is too invasive initially:
1. Download Bonsai safetensors from HuggingFace
2. Convert using turboquant's `convert_hf_to_gguf.py` (has `dequant_bitnet`)
3. This uses our native TQ1_0 (type 34) instead of Q1_0 (type 40)
4. May differ in quantization quality but avoids all type conflicts

---

## Files in PrismML Fork (Source Locations)

| File | Key Content |
|------|-------------|
| `ggml/include/ggml.h:424-431` | Q1_0=40, Q1_0_g128=41 enum |
| `ggml/src/ggml-common.h` | block_q1_0, block_q1_0_g128 structs |
| `ggml/src/ggml.c:654-669` | Type traits for Q1_0, Q1_0_g128 |
| `ggml/src/ggml-quants.c:65-419` | quantize/dequantize implementations |
| `gguf-py/gguf/constants.py:3830-3831` | Python LlamaFileType entries |
| `convert_hf_to_gguf.py:273-400` | BitNet conversion (dequant_bitnet) |
| `.github/workflows/release-prism.yml` | Pre-built binary release CI (unique to PrismML) |
