# P-EAGLE Foundation Progress

Date: `2026-04-03`

## Scope

This pass implemented the cleanup-first P-EAGLE foundation on the active THOTH feature branch:

- THOTH branch: `sglang-turboquant-1-bit_gfx1030`
- `forks/sglang` branch: `sglang-turboquant-1-bit_gfx1030`
- `forks/SpecForge` branch: `thoth/eagle3-runtime-clean`

## Cleanup Outcome

- `forks/sglang`
  - restored the validated runtime branch to the pushed clean state
  - preserved dirty post-validation experiments on `local/dual-eagle3-experiments-rocm`
- `forks/SpecForge`
  - restored `main` to a clean upstream-aligned state
  - preserved reusable runtime code on `thoth/eagle3-runtime-clean`
  - preserved local config artifacts on `local/eagle3-configs-and-training`

## Implemented Foundation

### SpecForge

- Added P-EAGLE-oriented draft metadata fields to the training/config surface:
  - `speculative_algorithm`
  - `parallel_drafting`
  - `mask_token_id`
  - `k_train`
  - `cod_retention`
- Added `mask_hidden` to the LLaMA EAGLE3 draft head.
- Added `prepare_p_eagle_inputs(...)` to build:
  - slot 0 from the real token id + fused hidden state
  - slots `1..K-1` from the mask token + shared hidden state
- Kept this as an extension of the existing EAGLE3 draft path rather than a separate model family.
- Added draft-model unit coverage for:
  - P-EAGLE input construction
  - config/weight round-trip of `mask_hidden` and P-EAGLE config metadata

### SGLang

- Added speculative algorithm enum support for `P_EAGLE`.
- Extended server arg parsing so `--speculative-algorithm P_EAGLE` is accepted.
- Added draft-checkpoint validation for `parallel_drafting: true`.
- Added `mask_hidden` and `mask_token_id` to the local `llama_eagle3` runtime model so future P-EAGLE checkpoints can load without dropping parameters.
- Added a runtime helper for constructing P-EAGLE draft inputs in the local EAGLE3 model.

## Validation

### Successful checks

- Python syntax compilation passed for the edited files in both repos.
- The main ROCm venv at `/home/local/python/.venv-pytorch-rocm` now has the minimum extra packages needed to start resolving local imports:
  - `transformers`
  - `pybase64`
  - `psutil`
  - `pyzmq`
  - supporting `pytest` packages

### Remaining blocker

Full `SpecForge` unit execution is still blocked by environment completeness, not by the new code itself.

The current blocker path is:

- importing `specforge` triggers the full package init chain
- that pulls in local `sglang`
- local `sglang` still expects additional runtime dependencies in the shared ROCm venv

This means the next productivity step is environment completion for the shared ROCm Python stack, then rerunning:

```bash
VENV=/home/local/python/.venv-pytorch-rocm
PATH="$VENV/bin:$PATH" \
PYTHONPATH=/home/local/Projects/THOTH/forks/sglang/python \
"$VENV/bin/python" -m unittest tests.test_modeling.test_draft.test_llama3 -v
```

## Next Step

Finish the shared ROCm venv wiring, rerun the lightweight `SpecForge` draft-model tests, then decide whether to:

1. push the current P-EAGLE foundation commits as-is, or
2. continue directly into the first SGLang runtime hook that actually consumes `parallel_drafting`.
