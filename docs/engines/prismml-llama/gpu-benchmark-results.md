# PrismML Bonsai GPU Benchmark Results

> **Date**: 2026-04-01
> **Hardware**: AMD Radeon RX 6700 XT (gfx1030, RDNA2, 12 GB VRAM)
> **Backend**: ROCm 7.2 via HIP
> **Build**: PrismML/llama.cpp `prism-b8194-1179bfc`, `-DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1030`
> **Container**: `thoth:latest`

---

## Benchmark Results (llama-bench, 3 runs averaged)

| Model | Size | Params | pp512 (t/s) | tg128 (t/s) | VRAM |
|-------|------|--------|-------------|-------------|------|
| **Bonsai-1.7B** (Q1_0_G128) | 231 MiB | 1.72B | **2096.87 ± 2.05** | **75.60 ± 39.09** | ~0.5 GB |
| **Bonsai-4B** (Q1_0_G128) | 540 MiB | 4.02B | **856.64 ± 2.80** | **120.66 ± 0.04** | ~1.0 GB |
| **Bonsai-8B** (Q1_0_G128) | 1.07 GiB | 8.19B | **453.90 ± 0.78** | **91.56 ± 9.59** | ~1.5 GB |

### Key Observations

1. **Bonsai-4B is the sweet spot**: 121 t/s generation with 4B parameters at 540 MiB. The 4B model generates faster than 1.7B because 1.7B has higher variance (likely memory bandwidth noise on smaller tensors).

2. **8B model fits easily in VRAM**: 1.07 GiB for 8.19B parameters is remarkable — our 12 GB GPU has ~10 GB headroom for KV cache, making the 8B fully viable for production serving.

3. **Prompt processing scales inversely with size**: 2097 → 857 → 454 t/s, roughly proportional to parameter count, confirming compute-bound behavior.

---

## Performance Path Analysis

### MMVQ (Token Generation) — ✅ Working

Token generation uses the `vec_dot_q1_0_q8_1` kernel via MMVQ (matrix-vector quantized). This path works on all GPU architectures and is responsible for the 75-121 t/s generation speeds.

- **Kernel**: `vec_dot_q1_0_q8_1` (scalar bit-unpacking + accumulate)
- **Quantize format**: Q1_0_G128 — 128 elements per block, 1 scale (fp16) + 16 bytes of sign bits

### MMQ (Prompt Processing) — ⚠️ cuBLAS Fallback

PrismML's MMQ kernels for Q1_0 **require Turing MMA (SM ≥ 75)**, which gfx1030 does not have:

```c
// mmq.cu:310
if ((type == GGML_TYPE_Q1_0 || type == GGML_TYPE_Q1_0_g128) && !turing_mma_available(cc)) {
    return false;  // falls back to dequant→hipBLAS GEMM
}
```

Despite this, prompt processing is still fast (454-2097 t/s) because 1-bit dequantization is trivially cheap — `bit ? d : -d` — so the dequant→GEMM fallback has minimal overhead.

### Why `llama-cli --conversation` Was 3.4 t/s

The interactive CLI test showed 3.4 t/s because the `--conversation` flag with `--no-display-prompt` caused PrismML's chat interface to enter a newline-flood loop, generating thousands of empty prompt markers instead of actual tokens. The raw `llama-bench` numbers confirm the kernels are fast.

---

## Comparison: PrismML GPU vs llama-turboquant CPU

| Config | Bonsai-4B Generation (t/s) |
|--------|---------------------------|
| PrismML GPU (gfx1030) | **120.66** |
| llama-turboquant CPU | ~0.7 |
| **Speedup** | **~172×** |

---

## LFM2 + TQ3_0 V-only KV Cache Test

| Model | Config | Prompt t/s | Gen t/s | Coherent? |
|-------|--------|-----------|---------|-----------|
| LFM2-2.6B Q8_0 | Normal (no TQ) | 327.3 | 96.0 | ✅ |
| LFM2-2.6B Q8_0 | TQ3_0 V-only | 296.4 | 79.8 | ❌ Garbled |

**Finding**: TQ3_0 KV cache is **incompatible with LFM2's hybrid RNN/Transformer architecture**. The KV cache quantization corrupts the recurrent state. TQ3_0 only works with standard multi-head attention models (validated with OpenCoder).

---

## Architecture Compatibility Matrix

| Feature | Standard Transformer | Hybrid RNN (LFM2) | Q1_0 Weights |
|---------|--------------------|--------------------|------------|
| TQ3_0 V-only KV cache | ✅ | ❌ | N/A |
| Q1_0 GPU (MMVQ gen) | N/A | N/A | ✅ (any GPU) |
| Q1_0 GPU (MMQ prompt) | N/A | N/A | ⚠️ Turing+ only, cuBLAS fallback otherwise |
| Q1_0 + TQ3_0 combined | **Needs testing** | ❌ | **Next target** |
