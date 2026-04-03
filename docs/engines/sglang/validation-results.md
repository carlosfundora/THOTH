# SGLang — Validation Results

**Last Updated:** 2026-04-03  
**Status:** Validated OpenCoder `tq4` local `EAGLE3` Docker path; validated Bonsai `tq4` local `EAGLE3` Docker path  
**Engine Role:** Primary target for true speculative decoding, EAGLE, TurboQuant serving, and training handoff

---

## Summary

The SGLang ROCm port is past the old startup-only phase. The current validated
state is:

- `OpenCoder-1.5B + local EAGLE3 + tq4 + Triton + radix` works in Docker and returns `200 OK`
- `Bonsai-1.7B + local EAGLE3 + Triton + radix` works in Docker and returns `200 OK`
- `Bonsai-1.7B + local EAGLE3 + tq4 + Triton + radix` now works in Docker and returns `200 OK`

That means the synced branch can now carry one validated OpenCoder `tq4`
speculative path and one validated Bonsai 1-bit speculative `tq4` path on the
same ROCm runtime stack.

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
- [`/home/local/Projects/THOTH/logs/20260403T071037_opencoder15_eagle3_tq4_typefix_canary_response.json`](/home/local/Projects/THOTH/logs/20260403T071037_opencoder15_eagle3_tq4_typefix_canary_response.json)
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
4. `/generate` returns `200`
5. Triton stays active
6. radix stays active
7. both target and draft workers keep `tq4` enabled

Primary evidence:

- [`/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md)
- [`/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json)
- [`/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_resources.jsonl)
- [`/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2.log`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2.log)

### Historical Bonsai 1.7B `tq4` blocker

Historical evidence from the pre-fix boundary:

- [`/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-blocker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-blocker-2026-04-03.md)
- [`/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log)
- [`/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl)

---

## Runtime Notes

- The critical Bonsai fix sequence was:
  - restore correct GGUF F32/F16/BF16 type-name handling so norm weights are not misloaded as quantized `qweight`s
  - preserve draft projection dtype in `llama_eagle3.py` so the draft-local embedding fallback does not feed `float32` into `Half` projection weights

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| ROCm server boot | ✅ | runtime boots in Docker |
| Triton fallback policy | ✅ | `aiter` auto-selection fixed |
| OpenCoder 1.5B local `EAGLE3` | ✅ | `tq4`, Triton, radix, Docker request path validated |
| Bonsai 1.7B local `EAGLE3` | ✅ | non-`tq` 1-bit path validated |
| Bonsai 1.7B local `EAGLE3` + `tq4` | ✅ | request path validated after GGUF loader + draft projection dtype fixes |

---

## Next Step

The next required sequence is now:

1. sync the validated OpenCoder and Bonsai `tq4` runtime state
2. keep both validated Docker paths as regression canaries while cleaning the branch
3. next runtime goal: test simultaneous `EAGLE3` behavior on both the draft model and the generation model
4. only then widen back out to OpenCoder 8B, Bonsai 4B, or training
