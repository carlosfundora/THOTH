# llama-turboquant — Validation Results

**Last Updated:** 2026-04-02  
**Status:** Validated for HIP proof-of-life, OpenCoder baseline and draft-model speculation, TurboQuant V-cache, and Bonsai Q1 compatibility  
**Engine Role:** Primary gfx1031-as-gfx1030 Docker HIP proof path for THOTH

---

## Summary

`llama-turboquant` is the most complete working engine in THOTH right now for:

- gfx1031 running as `gfx1030` inside Docker
- OpenCoder GGUF baseline inference
- ordinary draft-model speculative decoding
- quantized V-cache experiments
- Bonsai `Q1_0` / `Q1_0_G128` compatibility after the Q1 remap port

Important boundary:

- this engine proves plain `--model-draft` speculation
- it does **not** prove a first-class llama-side `EAGLE3` runtime
- true EAGLE remains an SGLang-track goal

---

## Historical Benchmark Format

The canonical historical benchmark format for this engine is the matrix style from
[`smoke-tests-run001.md`](./smoke-tests-run001.md): config, cache mode,
prompt/gen throughput, context MiB, and quality. That is the format used below.

### Historical OpenCoder-1.5B Matrix (2025-07-14)

| Config | Cache-K | Cache-V | Flash Attn | Prompt t/s | Gen t/s | Context MiB | Quality |
|--------|---------|---------|------------|-----------:|--------:|------------:|---------|
| Baseline | f16 | f16 | auto (off) | 164.9 | 134.4 | 840 | ✅ Coherent |
| TQ3_0 K-only | tq3_0 | f16 | forced off | 80.9 | 139.9 | 511 | ❌ Garbled |
| TQ3_0 V-only | f16 | tq3_0 | on | 316.0 | 81.4 | 511 | ✅ Coherent |
| q8_0 V-only | f16 | q8_0 | on | 316.7 | 84.2 | 643 | ✅ Coherent |

### Historical OpenCoder-8B Matrix (2025-07-14)

| Config | Cache-K | Cache-V | Flash Attn | Prompt t/s | Gen t/s | Context MiB | Quality |
|--------|---------|---------|------------|-----------:|--------:|------------:|---------|
| Baseline | f16 | f16 | auto | 346.0 | 59.2 | 1024 | ✅ Coherent |
| TQ3_0 V-only | f16 | tq3_0 | on | 266.4 | 41.5 | 624 | ✅ Coherent |

Historical source:
- [`smoke-tests-run001.md`](./smoke-tests-run001.md)

---

## Draft-Model Speculation Validation

Validated pair:

- target: `OpenCoder-8B-Instruct.Q4_K_M.gguf`
- draft: `OpenCoder-1.5B-Instruct.Q4_K_M.gguf`

### Historical Speculation Results

These results were originally recorded in a misnamed EAGLE document, but the
actual tested path was plain llama draft-model speculation:

| Config | Prompt t/s | Gen t/s | Free VRAM MiB | Unaccounted MiB | Quality |
|--------|-----------:|--------:|--------------:|----------------:|---------|
| 8B baseline | 346.0 | 59.2 | 6530 | 219 | ✅ Coherent |
| 8B + 1.5B draft | 359.9 | 49.3 | 3276 | 3473 | ✅ Coherent |

Historical source:
- [`eagle-speculative-results.md`](./eagle-speculative-results.md)

### Run 002 Draft-Model Speculation Results (2026-04-01)

| Config | Prompt t/s | Gen t/s | Notes |
|--------|-----------:|--------:|-------|
| 8B + 1.5B draft | 390.1 | 50.6 | fresh Docker rebuild from live THOTH source |
| 8B + 1.5B draft + `tq3_0` V-cache | 267.9 | 37.9 | required `--flash-attn on` |

Run 002 source:
- [`eagle-speculative-results-run002-2026-04-01.md`](./eagle-speculative-results-run002-2026-04-01.md)

Server-side smoke for the same config also passed:
- `/health` => `200`
- `/completion` => `200`
- draft stats: `draft_n=17`, `draft_n_accepted=10`, acceptance rate `0.58824`

Server evidence:
- [`20260401T212928_opencoder_q4_server_tq3v_fa.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212928_opencoder_q4_server_tq3v_fa.log)

---

## Monitored Rerun Matrix (2026-04-02)

This rerun added live host RAM, swap, GPU VRAM, GPU temperature, Docker memory,
and Docker CPU sampling for each case.

### OpenCoder-1.5B Monitored Rerun

| Config | Cache-K | Cache-V | Flash Attn | Draft | Prompt t/s | Gen t/s | Context MiB | Unaccounted MiB | Peak VRAM GiB | Peak Docker Mem GiB | Peak CPU % | Peak Junction C |
|--------|---------|---------|------------|-------|-----------:|--------:|------------:|----------------:|--------------:|--------------------:|-----------:|----------------:|
| Baseline | f16 | f16 | off | no | 188.1 | 124.1 | 210 | 600 | 2.27 | 2.79 | 1204.38 | 42 |
| TQ3_0 K-only | tq3_0 | f16 | off | no | 74.2 | 126.6 | 127 | 600 | 2.30 | 2.79 | 1208.96 | 43 |
| TQ3_0 V-only | f16 | tq3_0 | on | no | 47.6 | 3.1 | 127 | 550 | 3.81 | 3.04 | 1201.21 | 44 |
| q8_0 V-only | f16 | q8_0 | on | no | 56.5 | 3.7 | 160 | 551 | 3.82 | 3.04 | 1237.62 | 44 |

### OpenCoder-8B Monitored Rerun

| Config | Cache-K | Cache-V | Flash Attn | Draft | Prompt t/s | Gen t/s | Context MiB | Unaccounted MiB | Peak VRAM GiB | Peak Docker Mem GiB | Peak CPU % | Peak Junction C |
|--------|---------|---------|------------|-------|-----------:|--------:|------------:|----------------:|--------------:|--------------------:|-----------:|----------------:|
| Baseline | f16 | f16 | auto | no | 349.5 | 54.7 | 128 | 537 | 6.39 | 7.42 | 1211.92 | 44 |
| TQ3_0 V-only | f16 | tq3_0 | on | no | 37.5 | 1.6 | 78 | 531 | 6.72 | 7.43 | 1209.37 | 45 |
| 8B + 1.5B draft | f16 | f16 | auto | yes | 384.5 | 47.8 | 128 | 2207 | 8.41 | 7.32 | 1201.83 | 60 |
| 8B + 1.5B draft + `tq3_0` V-cache | f16 | tq3_0 | on | yes | 43.7 | 3.7 | 78 | 2073 | 8.23 | 7.54 | 1204.82 | 46 |

Monitored rerun evidence:
- [`20260402T094137_llama_matrix_summary.json`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094137_llama_matrix_summary.json)

Case logs:
- [`20260402T094137_opcoder15_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094137_opcoder15_baseline.log)
- [`20260402T094141_opcoder15_tq3k.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094141_opcoder15_tq3k.log)
- [`20260402T094145_opcoder15_tq3v.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094145_opcoder15_tq3v.log)
- [`20260402T094201_opcoder15_q8v.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094201_opcoder15_q8v.log)
- [`20260402T094216_opcoder8_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094216_opcoder8_baseline.log)
- [`20260402T094224_opcoder8_tq3v.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094224_opcoder8_tq3v.log)
- [`20260402T094253_opcoder8_draft.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094253_opcoder8_draft.log)
- [`20260402T094300_opcoder8_draft_tq3v.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094300_opcoder8_draft_tq3v.log)

### Monitored Rerun Readout

- The baseline 8B path remains healthy.
- The 8B draft path still works and remains the correct proof that ordinary
  speculative decoding is functioning on llama.
- The rerun materially changed the observed V-cache behavior versus the
  historical 2025-07-14 numbers: both `tq3_0` V-only and `q8_0` V-only were
  much slower in this 2026-04-02 rerun.
- Because this rerun was optimized for resource capture rather than qualitative
  rescoring, semantic output quality should still be taken from the historical
  run matrix unless a case is explicitly re-reviewed.

---

## Segfault Fix

The invalid quantized V-cache path without Flash Attention previously emitted the
correct validation error and then segfaulted. That failure now exits cleanly.

Evidence:
- [`20260401T212652_opencoder_q4_speculative_tq3v.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212652_opencoder_q4_speculative_tq3v.log)
- [`20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log)

---

## Hardening Update (2026-04-03)

The runtime hardening pass added narrow regressions around the exact failure
classes that showed up later in the SGLang ROCm bring-up:

- GGUF float tensor types now have a loader regression so Bonsai-style norm
  tensors remain `F32` / `F16` / `BF16` through metadata load
- CLI parser coverage now explicitly includes `tq3_0` KV cache flags and
  `--no-host`
- the server test suite now preserves the fail-fast guard that rejects
  quantized V-cache with Flash Attention forced off
- server docs now call out `tq3_0` cache values and the ROCm host-buffer policy

Hardening evidence:
- [`/home/local/Projects/THOTH/reports/llama-turboquant/rocm-hardening-2026-04-03.md`](/home/local/Projects/THOTH/reports/llama-turboquant/rocm-hardening-2026-04-03.md)

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| HIP build | ✅ | Docker rebuild succeeds on gfx1030 compatibility target |
| OpenCoder baseline | ✅ | 1.5B and 8B both validated |
| Draft-model speculation | ✅ | plain llama drafting works on GPU |
| TurboQuant V-cache | ✅ | valid runtime path exists; monitored rerun showed degraded speed |
| `llama-server` | ✅ | health and completion validated for speculative + `tq3_0` |
| Bonsai Q1 compatibility | ✅ | all three models load and generate |
| True EAGLE / EAGLE3 | ❌ | not a completed llama-side runtime path |

---

## Next Step

`llama-turboquant` is complete enough as proof-of-life. Active work should stay
on SGLang for:

- stable speculative generation
- true EAGLE / EAGLE3 runtime validation
- later OpenCoder EAGLE training follow-through

Upstreaming status from this pass:

- review branches are ready in `carlosfundora/llama-turboquant` for:
  - `review/prismml-q1-support`
  - `review/null-context-guard`
  - `review/rocm-hardening`
- standalone `forks/llama.cpp` upstream prep is still blocked until the local
  ROCm null-context patch is rebuilt as a real source diff rather than the
  accidental symlink placeholder currently on `master`
