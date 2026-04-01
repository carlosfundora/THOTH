# EAGLE Speculative Decoding — Test Results (Run 001)

**Date:** 2025-07-14
**Hardware:** RX 6700 XT (gfx1031→gfx1030), 12,272 MiB VRAM
**Binary:** llama-turboquant (b0-unknown), HIP/ROCm 7.2.0

---

## Test: OpenCoder-8B main + OpenCoder-1.5B draft

```bash
llama-cli \
  --model OpenCoder-8B-Instruct.Q4_K_M.gguf \
  --model-draft OpenCoder-1.5B-Instruct.Q4_K_M.gguf \
  --n-gpu-layers 99 -ngld 99 \
  --single-turn \
  -p "Write a Python quicksort function:" -n 64
```

### Results

| Metric | 8B Baseline (no draft) | 8B + 1.5B Draft |
|--------|----------------------|-----------------|
| Prompt | 346.0 t/s | 359.9 t/s |
| Generation | 59.2 t/s | 49.3 t/s |
| Context MiB | 1,024 | 1,024 |
| Free VRAM | 6,530 MiB | 3,276 MiB |
| Unaccounted VRAM | 219 MiB | 3,473 MiB |
| Quality | ✅ Coherent | ✅ Coherent |

### Timing Breakdown (from llama_perf_context_print)
```
load time   = 1749.75 ms
prompt eval = 261.32 ms / 41 tokens (6.37 ms/tok, 156.9 t/s)
eval time   = 680.94 ms / 53 runs (12.85 ms/tok, 77.8 t/s)
total time  = 2910.13 ms / 94 tokens
graphs reused = 53
```

### Analysis

**EAGLE did not provide a generation speedup** — generation dropped from 59.2 → 49.3 t/s (17% slower).

**Why it didn't help:**
1. **Not a proper EAGLE pair** — OpenCoder-1.5B and 8B are independently trained models, not a distilled EAGLE draft. True EAGLE requires a purpose-built draft head trained to predict the main model's next tokens.
2. **VRAM overhead** — The draft model consumed ~3.2 GB additional VRAM (3473 MiB unaccounted), leaving only 3.3 GB free. On a 12 GB card, this is significant.
3. **No speculative benefit** — 53 eval runs for 53 generated tokens = 1:1 ratio (no speculation). A working EAGLE pair should show significantly fewer runs than tokens.

### What Would Work Better
- **Purpose-built EAGLE draft head** for OpenCoder-8B (doesn't exist yet)
- **Smaller draft model** — a proper 0.5B or 1B distilled predictor
- **Different speculation strategy** — the `--draft-max` and `--draft-min` flags could tune acceptance rate
- **More VRAM headroom** — on a 24 GB card, the overhead would be acceptable

---

## Status
- [x] EAGLE infrastructure works (dual model loading, speculation framework)
- [x] Both models load on GPU simultaneously
- [ ] No speedup achieved — need purpose-built draft model
- [ ] Not tested: EAGLE with TQ3_0 V cache (would free VRAM for draft model)
