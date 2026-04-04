# Turbo Engine Sync Assessment

> Date: 2026-04-04
> Baseline protected from regression: `runtime + training`

This review answers two questions:

1. How do the newer public `1-bit`, `TurboQuant`, and speculative-decoding repos compare to THOTH's current deployed surface?
2. Which THOTH forks can be synced to current upstream heads without breaking deployed features?

## Protected Non-Breaking Baseline

`sglang` is only considered preserved if a sync candidate can still run:

- `1-bit` Bonsai GGUF
- `TurboQuant`
- `radix`
- `Triton`
- `EAGLE3`
- speculative decoding

in the same deployed runtime path, while still recognizing THOTH/SpecForge `P-EAGLE` checkpoints.

`llama.cpp` is only considered preserved if a sync candidate can still run the previously working:

- Prism/Bonsai `1-bit` path
- prior TurboQuant KV/runtime behavior
- current server startup failure handling or an equivalent guardrail

## Current THOTH Fork State

### `forks/llama.cpp`

- remote upstream: `TheTom/llama-cpp-turboquant`
- current upstream head: `e43970099269b5b6da36b8977ad47697602e4e54`
- local state after refresh: `20 behind / 1 ahead`
- only local custom commit:
  - `92724c9ec` `fix(server): fail fast when model context creation fails`
- only overlapping file with current upstream drift:
  - `tools/server/server-context.cpp`

Practical reading: this is still a narrow fork. It is syncable in principle, but only after replaying or re-evaluating the null-context guard in `server-context.cpp`.

### `forks/sglang`

- remote upstream: `sgl-project/sglang`
- current upstream head: `ef1303124f4d8cd16119765422f3e8a4876751f2`
- local state after refresh: `183 behind / 6 ahead`
- custom commit stack:
  - `465b883f3` `feat: recognize p-eagle draft checkpoints`
  - `e8da8e785` `fix: stabilize rocm eagle3 tq4 runtime`
  - `00a7a319a` `fix(rocm): sync validated EAGLE and tq4 runtime subset`
  - `c81f5f36c` `fix: fallback ROCm attention backend to triton without aiter`
  - `a1b689771` `feat(rocm): port TurboQuant and EAGLE3 speculative decode to HIP with GGUF 1-bit fallback`
  - `e463f2bff` `[AMD] Add TurboQuant KV cache compression (--kv-cache-dtype tq2/tq3/tq4)`
- current local custom surface:
  - 49 changed files
  - 18,795 insertions
  - 144 deletions
- overlapping hot files with current upstream drift:
  - `python/sglang/srt/configs/model_config.py`
  - `python/sglang/srt/layers/rotary_embedding/base.py`
  - `python/sglang/srt/mem_cache/memory_pool.py`
  - `python/sglang/srt/model_executor/forward_batch_info.py`
  - `python/sglang/srt/model_executor/model_runner.py`
  - `python/sglang/srt/model_executor/model_runner_kv_cache_mixin.py`
  - `python/sglang/srt/model_loader/loader.py`
  - `python/sglang/srt/model_loader/weight_utils.py`
  - `python/sglang/srt/models/llama_eagle3.py`
  - `python/sglang/srt/models/qwen3.py`
  - `python/sglang/srt/server_args.py`
  - `python/sglang/srt/speculative/eagle_info.py`
  - `python/sglang/srt/utils/hf_transformers_utils.py`

Practical reading: this is not a simple sync candidate. The overlap is concentrated in the exact runtime paths THOTH needs to preserve.

## Public Comparison Matrix

| Repo | Runtime family | Hardware target | 1-bit support | TurboQuant support | Runtime extras | Training relevance | Sync relevance to THOTH | Assessment |
|---|---|---|---|---|---|---|---|---|
| `PrismML-Eng/Bonsai-demo` | demo/orchestration | mixed | Bonsai GGUF via referenced forks | none in repo | launch scripts only | none | donor/reference | Useful for distribution and release references, not a serving-engine replacement |
| `PrismML-Eng/llama.cpp` | `llama.cpp` fork | CUDA, Metal, Linux/Windows per demo docs | yes, Prism `Q1_0` / `Q1_0_g128` via public demo references | not established from demo alone | no public evidence here for radix, Triton serving, or EAGLE runtime | none | donor/reference | Important reference fork, but public demo surface alone does not prove broader engine depth than THOTH |
| `nisten/prism-ml-biturbo` `main` | `llama.cpp` fork | CUDA | yes, Prism/Bonsai 1-bit on Prism base | yes, `TBQ4_0` | CUDA quant/dequant, dp4a path for non-RTX Turing | none | donor/reference | Serious `llama.cpp` comparator; still CUDA-only and not a `sglang` competitor |
| `nisten/prism-ml-biturbo` `optimize` | `llama.cpp` fork | CUDA | yes | yes, `TBQ4_0` | adds Hadamard rotation foundation port on top of `main` | none | donor/reference | Good donor for CUDA-side TBQ/Hadamard ideas, still not relevant as an `sglang` replacement |
| `TheTom/llama-cpp-turboquant` | `llama.cpp` fork | mixed, with HIP documentation | no public Prism guarantee by default | yes | direct runtime baseline for our `llama.cpp` fork | none | direct upstream | Primary sync base for `forks/llama.cpp` |
| `TheTom/turboquant_plus` | research/integration workspace | mixed | none | yes | benchmark and quality experiments, sparse V, layer-aware configs | none | donor/reference | Algorithm and validation donor, not the serving branch to sync against |
| `AmesianX/TurboQuant` | `llama.cpp`-derived patch stack | CUDA first, some ROCm notes | none on Prism-specific path from inspected README | yes | many TBQ/TBQP variants, head-dim handling, patch-oriented integration | none | donor/reference | Useful patch-stack reference, but narrower and less aligned to THOTH than our current ROCm runtime stack |
| `sgl-project/sglang` | serving runtime | CUDA and ROCm upstream churn | none for Prism/Bonsai 1-bit out of the box | upstream AMD TQ donor lineage exists | Triton, radix, speculative runtime | checkpoint/runtime compatible paths matter | direct upstream | Must remain the base for `forks/sglang`, but current sync must preserve THOTH's added 1-bit/TQ/EAGLE/P-EAGLE surface |
| `vllm-project/speculators` | training/speculation library | mixed | none | none | speculative training and deployment format | active training support | donor/reference | Relevant to training/runtime semantics, not a serving-engine sync target |

## Public Fork Conclusions

- `nisten/prism-ml-biturbo` is the strongest new public `llama.cpp` comparator in this review. It clearly implements Prism/Bonsai 1-bit support plus `TBQ4_0`, but it is still a CUDA-first `llama.cpp` fork. It does not reduce the need for THOTH's custom `sglang` runtime.
- `PrismML-Eng/Bonsai-demo` is still an orchestration/demo surface. It proves packaging and release intent, not a public `sglang`-equivalent runtime stack.
- `TheTom/turboquant_plus` remains the best public algorithm/benchmark donor, not the fork to sync serving code against.
- `AmesianX/TurboQuant` is a useful patch-stack reference, especially around head-dim handling and broader TBQ variants, but it is not a better sync base for THOTH than our current `llama.cpp` or `sglang` bases.
- `vllm-project/speculators` is important for training and standardized speculative model semantics, but it does not replace THOTH's current serving requirements.

## Safe-Sync Recommendation

### `llama.cpp`: Safe to Attempt in a Review Branch

Default path:

1. Sync `forks/llama.cpp` to current `TheTom/llama-cpp-turboquant` head `e43970099269b5b6da36b8977ad47697602e4e54` in a review branch.
2. Reapply or re-implement the local null-context guard only if upstream still lacks equivalent protection.
3. Do not import `nisten/prism-ml-biturbo` wholesale.
4. Only borrow from `nisten/prism-ml-biturbo` selectively if current upstream still lacks a specific Bonsai/TurboQuant behavior THOTH needs.

Why this is plausible:

- there is only one local patch
- there is only one overlapping file
- current upstream already carries many unrelated improvements without broad conflict

Blocking gate:

- if current upstream plus the retained guard loses the previously working 1-bit Bonsai or TurboQuant runtime path, the sync is rejected and stays on a review branch

### `sglang`: Not Safe to Sync Blindly

Default path:

1. Create a review branch from current upstream head `ef1303124f4d8cd16119765422f3e8a4876751f2`.
2. Reapply THOTH's custom surface in buckets:
   - must-preserve serving features
   - must-preserve training/runtime compatibility
   - ROCm-only hardening
   - maybe-obsolete patches only after proof
3. Rebuild the combined runtime path before considering any cleanup.

Protected buckets that may not regress:

- Prism/Bonsai 1-bit GGUF compatibility
- TurboQuant KV cache types and runtime wiring
- radix + Triton coexistence
- EAGLE3 runtime support
- speculative decoding in the deployed combined path
- `P-EAGLE` checkpoint recognition / `parallel_drafting`
- ROCm/HIP runtime stability for all of the above
- THOTH/SpecForge checkpoint compatibility

Why this is not safe as a simple sync:

- 183 upstream commits have landed since the merge-base
- 13 overlapping hot files are exactly in model loading, KV cache, server args, and EAGLE runtime
- our local diff includes core Python runtime files and ROCm `sgl-kernel` HIP sources, not just docs or wrappers

## Required Regression Gates

### `llama.cpp`

The sync candidate is acceptable only if it still:

- loads and runs Prism/Bonsai 1-bit GGUF
- preserves prior TurboQuant KV/runtime behavior
- preserves current server startup failure handling or an equivalent safety guard

### `sglang`

The sync candidate is acceptable only if it still runs:

- `1-bit + TQ + radix + Triton + EAGLE3 + speculative decoding`

together in the deployed path, and also still:

- recognizes THOTH/SpecForge `P-EAGLE` checkpoints
- preserves runtime compatibility with trained draft checkpoints

## Operational Recommendation

- Proceed with a `llama.cpp` review-branch sync first.
- Do not update `forks/sglang` on `main` yet.
- Keep `sglang` on the validated THOTH branch until a staged upstream review branch passes the combined runtime gates above.
- Treat `nisten/prism-ml-biturbo` as a CUDA-side donor for selective ideas, not as a replacement base for either THOTH fork.
