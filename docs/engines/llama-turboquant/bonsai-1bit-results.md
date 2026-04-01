# Bonsai 1-bit Model Compatibility — Test Results (Run 001)

> **Update (2026-04-01):** The root cause (type ID conflict) has been resolved via an upstream port of Q1_0 types. All Bonsai models (1.7B, 4B, 8B) now load and run successfully. The initial assessment that 1.7B was "corrupt" was incorrect. See [`../prismml-llama/q1_0-port-results.md`](../prismml-llama/q1_0-port-results.md) for current status.

**Date:** 2025-07-14
**Binary:** llama-turboquant (b0-unknown), built with HIP/gfx1030
**Models Tested:**
- `Bonsai-4B.gguf` (546 MB, from `huggingface/Bonsai-4B-gguf/`)
- `Bonsai-8B.gguf` (1.1 GB, from `huggingface/Bonsai-8B-gguf/`)

---

## Result: ❌ FAILED — Tensor Offset Mismatch

All Bonsai GGUFs (1.7B, 4B, 8B) fail with the same class of error:

```
gguf_init_from_file_ptr: tensor 'blk.0.attn_k.weight' has offset 54611104, expected 169879520
gguf_init_from_file_ptr: failed to read tensor data
```

### Root Cause: GGML Type ID Conflict (Confirmed via Source Analysis)

**PrismML and turboquant assign CONFLICTING meanings to type IDs 40 and 41:**

| Type ID | PrismML Fork | Turboquant Fork |
|---------|-------------|----------------|
| **40** | `GGML_TYPE_Q1_0` (1-bit, 32-elem blocks, 6 bytes) | `GGML_TYPE_NVFP4` (NV float4) |
| **41** | `GGML_TYPE_Q1_0_g128` (1-bit, 128-elem blocks, 18 bytes) | `GGML_TYPE_TQ3_0` (TurboQuant 3-bit, 256-elem blocks) |

When turboquant reads a Bonsai GGUF with type 41 tensors:
- **It thinks:** TQ3_0 → block_size=256, type_size≈24 bytes
- **Actually:** Q1_0_g128 → block_size=128, type_size=18 bytes
- **Result:** `offset = type_size × n_elements / block_size` computes wrong → ~3x mismatch

### PrismML's Custom 1-bit Types (from source)

**Block structures** (`ggml/src/ggml-common.h`):
```c
// Q1_0: 32-element blocks, 6 bytes each (ternary: {-scale, 0, +scale})
#define QK1_0 32
typedef struct {
    ggml_half d;            // 2 bytes: scale
    uint8_t qs[QK1_0 / 8]; // 4 bytes: 1 bit per element
} block_q1_0;               // Total: 6 bytes → 0.1875 bytes/element

// Q1_0_g128: 128-element blocks, 18 bytes each (same algorithm, larger group)
#define QK1_0_g128 128
typedef struct {
    ggml_half d;                  // 2 bytes: scale
    uint8_t qs[QK1_0_g128 / 8];  // 16 bytes: 1 bit per element
} block_q1_0_g128;                // Total: 18 bytes → 0.140625 bytes/element
```

**Type traits** (`ggml/src/ggml.c:654-669`):
```c
[GGML_TYPE_Q1_0] = {
    .type_name = "q1_0", .blck_size = 32, .type_size = 6, .is_quantized = true,
    .to_float = dequantize_row_q1_0, .from_float_ref = quantize_row_q1_0_ref,
},
[GGML_TYPE_Q1_0_g128] = {
    .type_name = "q1_0_g128", .blck_size = 128, .type_size = 18, .is_quantized = true,
    .to_float = dequantize_row_q1_0_g128, .from_float_ref = quantize_row_q1_0_g128_ref,
},
```

**Python constants** (`gguf-py/gguf/constants.py:3830-3831`):
```python
class LlamaFileType(IntEnum):
    MOSTLY_Q1_0       = 40  # PrismML custom
    MOSTLY_Q1_0_g128  = 41  # PrismML custom
```

### File Details

| Model | Magic | GGUF Version | File Size | Tensors | KV Pairs |
|-------|-------|-------------|-----------|---------|----------|
| Bonsai-4B | GGUF | 3 | 546 MB | 0x20 (32) | 0x14 (20) |
| Bonsai-8B | GGUF | 3 | 1.1 GB | 0x20 (32) | 0x14 (20) |
| OpenCoder-1.5B (works) | GGUF | 3 | 1.4 GB | 0x2B (43) | 0x14 (20) |

The Bonsai files are ~3x smaller than comparably-sized standard models (546 MB for 4B params ≈ 1.1 bits/param), confirming genuine 1-bit quantization.

### Architecture Note

Bonsai models declare `general.architecture: qwen3` — NOT `bitnet`. Our fork has full `qwen3` support.
The failure is in the **GGUF tensor loader** (type ID interpretation), not the model architecture handler.

---

## Options to Fix

### Option A: Port Q1_0 types into turboquant with new IDs
- Assign new IDs: `Q1_0 = 42`, `Q1_0_g128 = 43` (after TQ3_0=41)
- Port block structs, type traits, quantize/dequantize kernels from PrismML
- **Problem:** PrismML GGUFs still hardcode type 40/41, so need either:
  - A GGUF reader shim that remaps IDs on load, or
  - Re-convert models after porting

### Option B: Re-convert Bonsai from safetensors using our fork
- Download PrismML's Bonsai safetensors (not GGUF)
- Use our `convert_hf_to_gguf.py` (which has `dequant_bitnet` support)
- This avoids the type ID conflict entirely
- **Caveat:** Our `dequant_bitnet` may produce different quantization than Q1_0

### Option C: Use PrismML's pre-built binary (separate track)
- PrismML provides pre-compiled binaries via GitHub Releases
- Run Bonsai models with PrismML binary, everything else with turboquant
- **Downside:** No TQ3_0, no unified binary

### Option D: Hybrid — add Q1_0 support AND remap on load
- Port Q1_0 code from PrismML into turboquant at IDs 42-43
- Add a GGUF reader compatibility layer: detect PrismML-origin files and remap type 40→42, 41→43
- **Best long-term fix** — full compatibility, single binary

### Recommended Path: Option D (hybrid port + remap)

**Files to modify in turboquant fork:**
1. `ggml/include/ggml.h` — add Q1_0=42, Q1_0_g128=43
2. `ggml/src/ggml-common.h` — add block_q1_0 and block_q1_0_g128 structs
3. `ggml/src/ggml.c` — add type traits entries
4. `ggml/src/ggml-quants.c` — port dequantize_row_q1_0[_g128] kernels
5. `ggml/src/gguf.cpp` — add type ID remapping for PrismML-origin files
6. `gguf-py/gguf/constants.py` — add new file type constants

---

## Status

- [x] Bonsai-1.7B GGUF — FIXED (loads successfully with Q1_0 remap)
- [x] Bonsai-4B GGUF — FIXED (loads successfully with Q1_0 remap)
- [x] Bonsai-8B GGUF — FIXED (loads successfully with Q1_0 remap)
- [x] Ported PrismML Q1_0 types into turboquant (Option D)
