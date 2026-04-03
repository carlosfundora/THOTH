# SGLang Main Commit Audit — 2026-04-03

Source trees:

- `/home/local/Projects/THOTH/forks/sglang`
- `/home/local/Projects/THOTH/forks/SpecForge`

## Audited commits

- `sglang` `e463f2bff` `[AMD] Add TurboQuant KV cache compression (--kv-cache-dtype tq2/tq3/tq4)`
- `SpecForge` `aa2ebe6` `fix: clamp block indices in dflash mask_mod to prevent OOB access`

## Result

No cherry-pick was needed.

- `SpecForge` `aa2ebe6` is already present in `specforge/core/dflash.py`
- `sglang` `e463f2bff` is already present in:
  - `python/sglang/srt/layers/quantization/turboquant_kv.py`
  - `python/sglang/srt/layers/quantization/turboquant_triton.py`
  - `python/sglang/srt/model_executor/model_runner_kv_cache_mixin.py`
  - `python/sglang/srt/server_args.py`
- overlapping files such as `memory_pool.py`, `model_runner.py`, and `server_args.py` already contain local ROCm-specific fixes on top of the upstream TurboQuant feature set

## Validation

Host `.venv-sglang` import check:

- Python `3.12.7`
- `sglang 0.5.9`
- `torch 2.9.1+rocm7.2.0.git7e1940d4`
- `triton 3.6.0+rocm7.2.0.gitba5c1517`

Container CLI check in `thoth`:

- `python -m sglang.launch_server --help` still exposes:
  - `--kv-cache-dtype {auto,...,tq4,tq3,tq2}`
  - `--speculative-algorithm {EAGLE,EAGLE3,NEXTN,STANDALONE,NGRAM}`
  - `--speculative-draft-model-path`

## Practical conclusion

The recent `main` commits were worth auditing, but they are not the missing piece for the current blocker.

The remaining work is runtime correctness:

- keep Triton + radix enabled
- preserve the local ROCm fallbacks already added in `memory_pool.py` and `model_runner.py`
- continue debugging the surviving `indexSelectSmallIndex ... Half` failure in the non-EAGLE `tq4` and `STANDALONE` generation paths
