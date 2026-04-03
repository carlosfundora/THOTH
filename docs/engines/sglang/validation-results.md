# SGLang — Validation Results

**Last Updated:** 2026-04-03  
**Status:** Validated OpenCoder `tq4` local `EAGLE3` Docker path; Bonsai non-`tq` validated; Bonsai `tq4` still blocked  
**Engine Role:** Primary target for true speculative decoding, EAGLE, TurboQuant serving, and training handoff

---

## Summary

The SGLang ROCm port is past the old startup-only phase. The current validated
state is:

- `OpenCoder-1.5B + local EAGLE3 + tq4 + Triton + radix` works in Docker and returns `200 OK`
- `Bonsai-1.7B + local EAGLE3 + Triton + radix` works in Docker and returns `200 OK`
- `Bonsai-1.7B + local EAGLE3 + tq4 + Triton + radix` still faults on the first real request

That means the synced branch can now carry one validated OpenCoder `tq4`
speculative path and one validated Bonsai 1-bit speculative path, while keeping
the active blocker narrowed to Bonsai `tq4`.

Recent `main`-branch audit result:

- `SpecForge` commit `aa2ebe6` is already present in `specforge/core/dflash.py`
- `sglang` commit `e463f2bff` is already present in the TurboQuant feature files
- no audit cherry-pick was needed; the remaining work is runtime correctness on top of the existing feature set

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
- [`/home/local/Projects/THOTH/reports/sglang/opencoder-baseline-2026-04-02.md`](/home/local/Projects/THOTH/reports/sglang/opencoder-baseline-2026-04-02.md)

### OpenCoder 1.5B Local `EAGLE3` + `tq4`

Validated outcomes:

1. server boot succeeds in Docker
2. `/model_info` returns `200`
3. `/generate` returns `200`
4. Triton stays active
5. radix stays active
6. `tq4` stays enabled on both target and draft workers

Primary evidence:

- [`/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md)
- [`/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json)
- [`/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_resources.jsonl)

### Bonsai 1.7B Local `EAGLE3`

Validated outcomes:

1. GGUF target boots in Docker
2. local draft boots in Docker
3. `/model_info` returns `200`
4. `/generate` returns `200`
5. Triton stays active
6. radix stays active

Primary evidence:

- [`/home/local/Projects/THOTH/logs/20260403T041132_sglang_bonsai17_eagle3_embedfix_response.json`](/home/local/Projects/THOTH/logs/20260403T041132_sglang_bonsai17_eagle3_embedfix_response.json)
- [`/home/local/Projects/THOTH/logs/20260403T041132_sglang_bonsai17_eagle3_embedfix_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T041132_sglang_bonsai17_eagle3_embedfix_resources.jsonl)

### Bonsai 1.7B Local `EAGLE3` + `tq4`

Validated outcomes:

1. GGUF target boots in Docker
2. local draft boots in Docker
3. `/model_info` returns `200`
4. target extend completes
5. first real request still aborts during draft extend / packed-KV handling

Primary evidence:

- [`/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-blocker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-blocker-2026-04-03.md)
- [`/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log)
- [`/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl)

---

## Current Blockers

### Bonsai `tq4`

- failure: `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`
- current trace points into the TurboQuant packed-KV compression/write path
- the queue is already poisoned by the time the draft extend begins

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| ROCm server boot | ✅ | runtime boots in Docker |
| Triton fallback policy | ✅ | `aiter` auto-selection fixed |
| OpenCoder 1.5B local `EAGLE3` | ✅ | `tq4`, Triton, radix, Docker request path validated |
| Bonsai 1.7B local `EAGLE3` | ✅ | non-`tq` 1-bit path validated |
| Bonsai 1.7B local `EAGLE3` + `tq4` | ❌ | first request still faults |

---

## Next Step

The next required sequence is now:

1. sync the validated OpenCoder and Bonsai non-`tq` runtime state
2. harvest the donor runtime pattern for Bonsai `tq4` from `dendrite`, `turboquant_plus`, and `llama-turboquant`
3. re-run `Bonsai-1.7B + EAGLE3 + tq4` with the donor-selected packed-KV write strategy
4. only then widen back out to OpenCoder 8B, Bonsai 4B, or training
