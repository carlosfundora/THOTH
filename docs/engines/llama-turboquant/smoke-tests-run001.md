# llama-turboquant — Smoke Test Results (Run 001)

**Date:** 2025-07-14
**Hardware:** AMD Radeon RX 6700 XT (gfx1031 → gfx1030 via HSA_OVERRIDE_GFX_VERSION=10.3.0)
**VRAM:** 12,272 MiB total
**Binary:** llama-cli b0-unknown, built with GNU 13.3.0, ROCm/HIP
**Container:** thoth:latest (Docker, GPU passthrough via /dev/kfd + /dev/dri)

---

## Build Configuration

```
cmake flags:
  -DGGML_HIP=ON
  -DGPU_TARGETS=gfx1030
  -DCMAKE_BUILD_TYPE=Release
  -DGGML_TURBOQUANT=ON    # NOTE: this flag does NOT actually exist in cmake;
                           # TQ3_0 is always compiled as a native ggml type
```

Flash attention: compiled in (runtime toggle `--flash-attn on|off|auto`)

---

## Test Matrix — OpenCoder-1.5B-Instruct Q4_K_M (1.4 GB)

| Config | Cache-K | Cache-V | Flash Attn | Prompt t/s | Gen t/s | Context MiB | Quality |
|--------|---------|---------|------------|-----------|---------|-------------|---------|
| Baseline | f16 | f16 | auto (off) | 164.9 | 134.4 | 840 | ✅ Coherent |
| TQ3_0 K-only | tq3_0 | f16 | forced off | 80.9 | 139.9 | 511 | ❌ Garbled ("Here Here Here") |
| TQ3_0 V-only | f16 | tq3_0 | on | **316.0** | 81.4 | 511 | ✅ Coherent |
| q8_0 V-only | f16 | q8_0 | on | **316.7** | 84.2 | 643 | ✅ Coherent |

## Test Matrix — OpenCoder-8B-Instruct Q4_K_M (4.5 GB)

| Config | Cache-K | Cache-V | Flash Attn | Prompt t/s | Gen t/s | Context MiB | Quality |
|--------|---------|---------|------------|-----------|---------|-------------|---------|
| Baseline | f16 | f16 | auto | 346.0 | 59.2 | 1024 | ✅ Coherent |
| TQ3_0 V-only | f16 | tq3_0 | on | 266.4 | 41.5 | 624 | ✅ Coherent |

---

## Critical Source-Level Finding: TQ3_0 K ↔ V Cache Conflict

**File:** `src/llama-context.cpp` (lines 2957–2974)

The code enforces a **mutual exclusion** between TQ3_0 K cache and quantized V cache:

1. **Line 2957:** If K cache is `TQ3_0`, flash attention is **forced OFF**
   ```
   if (params.type_k == GGML_TYPE_TQ3_0) {
       LLAMA_LOG_WARN("flash_attn is not supported with TQ3_0 K cache - forcing off");
       params.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_DISABLED;
   }
   ```

2. **Line 2973:** If V cache is quantized AND flash attention is disabled → **ERROR**
   ```
   if (ggml_is_quantized(params.type_v) && params.flash_attn_type == DISABLED) {
       LLAMA_LOG_ERROR("V cache quantization requires flash_attn");
       return nullptr;
   }
   ```

**Result:** `--cache-type-k tq3_0 --cache-type-v tq3_0` is **impossible** — the flags contradict.

### Valid TQ3_0 Configurations
| K cache | V cache | flash_attn | Works? | Notes |
|---------|---------|------------|--------|-------|
| tq3_0 | f16 | forced off | ✅ But garbled output | Quality degradation on 1.5B |
| f16 | tq3_0 | on (required) | ✅ Best config | 2x prompt speedup, good quality |
| tq3_0 | tq3_0 | conflict | ❌ Crashes | K forces FA off, V requires FA on |
| f16 | q8_0 | on (required) | ✅ Good | Slightly more VRAM than tq3_0 |

---

## Analysis

### V-only TQ3_0 is the winner
- **Prompt processing nearly 2x faster** (164.9 → 316.0 t/s on 1.5B)
- **Context memory reduced 39%** (840 → 511 MiB on 1.5B)
- **Output quality preserved** — coherent code generation
- **Tradeoff:** Generation speed drops ~40% (134.4 → 81.4 t/s on 1.5B)

### K-only TQ3_0 causes quality degradation
- Output was garbled repetition ("Here Here Here Here")
- Key vectors are more sensitive to aggressive 3-bit quantization
- The Walsh-Hadamard + codebook approach may lose critical attention pattern info

### 8B model shows same pattern
- V-only TQ3_0: prompt slightly slower than baseline but still fast (266 vs 346 t/s)
- VRAM savings: 1024 → 624 MiB context (39% reduction, same ratio)
- Generation: 59.2 → 41.5 t/s (30% slower)
- Quality: ✅ coherent

### VRAM Budget (8B model)
| Component | Baseline | TQ3_0 V-only |
|-----------|----------|--------------|
| Model weights | 4,302 MiB | 4,302 MiB |
| KV context | 1,024 MiB | 624 MiB |
| Compute | 196 MiB | 204 MiB |
| **Total GPU** | **5,522 MiB** | **5,130 MiB** |
| **Free VRAM** | **6,530 MiB** | **6,924 MiB** |

TQ3_0 V-only frees ~400 MiB on the 8B model — meaningful for longer context or batch.

---

## Recommendations

1. **Default config for gfx1031:** `--cache-type-v tq3_0 --flash-attn on` (keep K as f16)
2. **Do NOT use TQ3_0 for K cache** — quality degradation is severe
3. **The `--cache-type-k tq3_0 --cache-type-v tq3_0` flag combo from the original prompt is broken by design** — it's a source-level conflict, not a bug
4. For maximum VRAM savings with acceptable quality, use `--cache-type-v q4_0` (not yet tested)
5. Flash attention is **required** for any V cache quantization on this build

---

## Remaining Tests

- [ ] EAGLE speculative decoding (8B main + 1.5B draft)
- [ ] Bonsai 1-bit model loading (qwen3 arch)
- [ ] Vulkan backend (requires rebuild with `-DGGML_VULKAN=ON`)
- [ ] AWQ conversion and test (deferred to last)

---

## Environment
```
ROCm: 7.2.0
GPU: AMD Radeon RX 6700 XT (gfx1031, detected as gfx1030)
HSA_OVERRIDE_GFX_VERSION: 10.3.0
Wave Size: 32
VMM: no
Docker: thoth:latest (GPU passthrough)
```
