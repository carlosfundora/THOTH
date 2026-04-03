# SGLang — Validation Results

**Last Updated:** 2026-04-02  
**Status:** Runtime recovery in progress; local `EAGLE3` proof achieved, baseline `tq4`, and `STANDALONE` still unstable  
**Engine Role:** Primary target for true speculative decoding, EAGLE, TurboQuant serving, and training handoff

---

## Summary

The SGLang ROCm port is no longer blocked at startup. The current state after
fresh reruns is:

- OpenCoder 8B baseline server boot works
- OpenCoder 8B baseline `/health` works
- OpenCoder 8B baseline `/generate` works
- OpenCoder 1.5B local `EAGLE3` now works with a locally-built SpecForge draft
- OpenCoder 1.5B matched non-EAGLE baseline still faults on the first real `/generate`
- OpenCoder 8B `tq4` still crashes on the first real `/generate`
- OpenCoder `STANDALONE` still crashes on the first real `/generate`
- true `EAGLE3` is no longer blocked by missing local assets

This is better than the earlier bring-up state, but it is not yet the full
runtime gate needed for EAGLE or Medusa training.

---

## Runtime Matrix

Validated inside the `thoth` container:

| Component | Version |
|----------|---------|
| Python | `3.12.3` |
| PyTorch | `2.11.0+rocm7.2` |
| Torch HIP runtime | `7.2.26015` |
| Triton | `3.6.0` |
| SGLang | `0.5.10rc0` |
| `sgl_kernel` | `0.4.0` |
| Transformers | `5.4.0` |
| FastAPI | `0.135.3` |
| Uvicorn | `0.42.0` |
| Container image | `thoth:latest` |
| In-container ROCm target | `gfx1030` |
| Physical GPU | `gfx1031` |
| `aiter` | not installed |

---

## Validated Results

### ROCm Backend Recovery

Validated outcomes:

- HIP no longer incorrectly defaults to `aiter`
- recovered backend on this machine is `triton`
- radix remains in scope on AMD
- auto dtype now falls back to `float16` on ROCm when `dtype=auto`

Primary evidence:

- [`README.md`](./README.md)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log)

### OpenCoder 8B Baseline

Validated outcomes:

1. server boot succeeds
2. `/health` returns `200`
3. first real `/generate` returns `200`
4. baseline non-speculative generation is recovered on ROCm

Primary evidence:

- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline_resources.jsonl)
- [`/home/local/Projects/THOTH/reports/sglang/opencoder-baseline-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder-baseline-2026-04-02.md)

### OpenCoder 8B `tq4`

Validated outcomes:

1. server boot succeeds
2. `TurboQuant MHA KV Pool` initializes
3. `/health` returns `200`
4. first real `/generate` still GPU-faults

Primary evidence:

- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T110500_sglang_opencoder8b_tq4.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110500_sglang_opencoder8b_tq4.log)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T110500_sglang_opencoder8b_tq4_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110500_sglang_opencoder8b_tq4_resources.jsonl)
- [`/home/local/Projects/THOTH/reports/sglang/opencoder-tq4-radix-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder-tq4-radix-2026-04-02.md)

### OpenCoder `STANDALONE`

Validated outcomes:

1. target model loads
2. draft model loads
3. server reaches `/health` `200`
4. first real `/generate` still GPU-faults on the speculative path

Primary evidence:

- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T111000_sglang_opencoder8b_standalone.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T111000_sglang_opencoder8b_standalone.log)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T111000_sglang_opencoder8b_standalone_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T111000_sglang_opencoder8b_standalone_resources.jsonl)
- [`/home/local/Projects/THOTH/reports/sglang/opencoder-standalone-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder-standalone-2026-04-02.md)

### True `EAGLE3`

Validated outcomes:

1. a local SpecForge-built OpenCoder 1.5B draft artifact loads as `LlamaForCausalLMEagle3`
2. SGLang launches with `--speculative-algorithm EAGLE3`
3. `/health` returns `200`
4. `/generate` returns `200`
5. speculative metrics are exposed in the response

Measured request:

- completion tokens: `64`
- end-to-end latency: `54.50 s`
- effective output rate: `1.17 tok/s`
- spec accept rate: `0.3333`
- accepted draft tokens: `32 / 96`

Supporting evidence:

- [`README.md`](./README.md)
- [`/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-local-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-local-2026-04-02.md)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_sglang_opcoder15_eagle3.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_sglang_opcoder15_eagle3.log)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_opcoder15_eagle3_generate_response.json`](/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_opcoder15_eagle3_generate_response.json)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_opcoder15_eagle3_generate_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T161700_opcoder15_eagle3_generate_resources.jsonl)

### OpenCoder 1.5B Matched Baseline

Validated outcomes:

1. server boot succeeds
2. `/health` returns `200`
3. first real `/generate` still aborts with the ROCm `indexSelectSmallIndex ... Half` fault

Primary evidence:

- [`/home/local/Projects/THOTH/reports/sglang/opencoder15-baseline-fault-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder15-baseline-fault-2026-04-02.md)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T161900_sglang_opcoder15_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T161900_sglang_opcoder15_baseline.log)
- [`/home/local/Projects/THOTH/logs/hephaestion/20260402T161900_opcoder15_baseline_generate_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T161900_opcoder15_baseline_generate_resources.jsonl)

---

## Current Blockers

### TurboQuant

- failure: `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`
- current path still points back into the ROCm TurboQuant write/compression flow

### Speculative Decoding

- failure: `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`
- crash happens after `/health`, during the first real speculative request

### Baseline vs EAGLE

- local `EAGLE3` proof now exists
- the matched OpenCoder 1.5B baseline request still faults
- the next blocker is no longer asset availability; it is baseline/runtime consistency across decode paths

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| ROCm server boot | ✅ | runtime boots in Docker |
| Triton fallback policy | ✅ | `aiter` auto-selection fixed |
| OpenCoder baseline startup | ✅ | `/health` passes |
| OpenCoder baseline generation | ✅ | fresh `/generate` succeeded |
| OpenCoder `tq4` startup | ✅ | pool initializes, `/health` passes |
| OpenCoder `tq4` generation | ❌ | first request still faults |
| `STANDALONE` startup | ✅ | target + draft load |
| `STANDALONE` generation | ❌ | first request still faults |
| local true `EAGLE3` proof | ✅ | OpenCoder 1.5B local draft generated and served |
| OpenCoder 1.5B matched baseline | ❌ | first request still faults |

---

## Next Step

The next required sequence is now:

1. isolate and patch the remaining `indexSelectSmallIndex` ROCm crash in the
   remaining non-EAGLE request path
2. re-run OpenCoder `tq4`
3. re-run OpenCoder `STANDALONE`
4. improve the local OpenCoder EAGLE draft from proof artifact to trained artifact
5. only then move into Medusa training artifacts
