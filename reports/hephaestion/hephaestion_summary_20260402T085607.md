# Hephaestion Run Summary

## THOTH Context
Resumed the active SGLang ROCm port inside `/home/local/Projects/THOTH` after the earlier disk-pressure interruption. This run used the hardened THOTH Docker path and treated THOTH as the canonical home for safety scripts, logs, reports, manifests, and engine notes.

## Attack-Order Position
1. `forks/llama-turboquant` is complete enough as proof-of-life
2. `forks/sglang` is the active runtime target

## Target Project
`/home/local/Projects/THOTH/forks/sglang`

## Donor Repos Consulted
- `forks/sglang`
- `forks/SpecForge`
- prior THOTH SGLang docs and logs

## Environment Summary
- Container: `thoth`
- Container image: `thoth:latest`
- CPU cap: `12`
- Memory cap: `60G`
- Python: `3.12.3`
- PyTorch: `2.11.0+rocm7.2`
- Torch HIP runtime: `7.2.26015`
- Triton: `3.6.0`
- SGLang: `0.5.10rc0`
- `sgl_kernel`: `0.4.0`
- Transformers: `5.4.0`
- FastAPI: `0.135.3`
- Uvicorn: `0.42.0`
- GPU: `AMD Radeon RX 6700 XT`
- Compatibility mode: `HSA_OVERRIDE_GFX_VERSION=10.3.0`
- ROCm agent target in-container: `gfx1030`
- Physical card reported by `rocm-smi`: `gfx1031`
- `aiter`: not installed in the runtime container

## Docker Build Context
- THOTH Docker safety hardening is live:
  - `/home/local/Projects/THOTH/docker/preflight.sh`
  - `/home/local/Projects/THOTH/docker/hephaestion-guard.sh`
  - `/home/local/Projects/THOTH/docker/up.sh`
- Preflight now blocks low-disk starts.
- Guard now stops the `thoth` container on thermal or disk trips.

## Architecture Goal
Recover a valid ROCm baseline for SGLang with:
- radix enabled
- TurboQuant `tq4` enabled
- no dependence on unavailable `aiter`
- a stable path back toward `STANDALONE` and real EAGLE validation

## Selected Improvement
Patch the SGLang ROCm attention-backend policy so HIP no longer auto-selects `aiter` when `aiter` is not installed. The recovered default backend is now `triton`, which keeps radix in play while removing a false backend assumption from the port.

## Files Modified
- `/home/local/Projects/THOTH/forks/sglang/python/sglang/srt/server_args.py`
- `/home/local/Projects/THOTH/docs/engines/sglang/README.md`
- `/home/local/Projects/THOTH/docs/engines/sglang/porting-run002-2026-04-02.md`
- `/home/local/Projects/THOTH/reports/hephaestion/hephaestion_summary_20260402T085607.md`
- `/home/local/Projects/THOTH/manifests/sglang/20260402T085607.yaml`

## Compatibility Strategy Used
- `HSA_OVERRIDE_GFX_VERSION=10.3.0`
- THOTH Docker runtime caps
- ROCm backend fallback from missing `aiter` to `triton`
- radix kept enabled during validation
- `--disable-cuda-graph`
- `--disable-piecewise-cuda-graph`
- `--max-running-requests 1`
- `--disable-overlap-schedule` on the OpenCoder baseline

## Build Iterations Attempted
1. Re-ran Bonsai with radix enabled and forced `triton`
   - result: removed the old missing-`aiter` crash path
2. Patched backend auto-selection in `server_args.py`
3. Re-ran Bonsai without an explicit backend override
   - result: auto-selected `triton` on ROCm as intended
4. Launched OpenCoder 8B baseline with `tq4`
   - result: boot succeeded and `/health` returned `200`
5. Sent one real generation request
   - result: reproducible GPU fault in the radix/TurboQuant KV write path

## Validation Results
### Successes
- Docker safety hardening is active and previously validated.
- ROCm auto-backend policy no longer drifts to `aiter` when `aiter` is absent.
- OpenCoder 8B baseline with `tq4` now reaches:
  - full model load
  - TurboQuant MHA KV cache init
  - HTTP server startup
  - `/health` => `200`

### Failure Captured
- First real OpenCoder `/generate` request fails with:
  - `HSA_STATUS_ERROR_MEMORY_APERTURE_VIOLATION`
  - path: `radix_attention.py` -> `triton_backend.py` -> `memory_pool.py:set_kv_buffer()`
- This is now the active blocker.

## Current Status
- AMD/radix support is still in scope.
- The missing-`aiter` default was a real bug and is now patched.
- The current ROCm blocker is narrower and more useful:
  - radix + `tq4` generation faults in the KV write path
  - startup itself is now working

## Remaining Blockers
- `memory_pool.set_kv_buffer()` is still unsafe on this ROCm path during a real generation request.
- Bonsai GGUF still needs a clean end-to-end serve proof after the OpenCoder `tq4` blocker is fixed.
- OpenCoder `STANDALONE` and EAGLE remain downstream of this KV-cache write fix.

## Next Best Improvement
Patch the ROCm TurboQuant KV-cache write path used by radix attention so the first OpenCoder generation request no longer faults, then repeat the recovery ladder:
1. OpenCoder 8B baseline
2. OpenCoder `STANDALONE`
3. known-good EAGLE engine proof
