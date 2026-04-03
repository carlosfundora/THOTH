# vLLM-TurboQuant — Validation Results

**Last Updated:** 2026-04-02  
**Status:** Not yet tested  
**Engine Role:** Serving-focused follow-up after llama and SGLang proof paths

---

## Summary

No validation run has been completed yet for `vllm-turboquant`.

This file is a tracking ledger for the engine, not evidence of a completed
validation.

This engine remains in the THOTH attack order as a later serving-focused track,
after:

1. `llama-turboquant`
2. `turboquant_plus`
3. `sglang`

Primary planning evidence:

- [`README.md`](./README.md)

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| Install in container | ⏳ | not yet executed |
| TurboQuant tests | ⏳ | not yet executed |
| Serving smoke | ⏳ | not yet executed |
| Benchmark capture | ⏳ | not yet executed |

---

## Planned Validation

When this engine becomes active, the minimum validation set is:

1. install the fork in the THOTH Docker container
2. run `tests/quantization/test_turboquant.py`
3. validate serving with TurboQuant KV cache
4. capture baseline vs TurboQuant benchmark data

---

## Blocking Condition

This engine should stay dormant until SGLang is stable enough to prove:

- real generation on ROCm
- speculative decoding
- true EAGLE engine path

Only after that should `vllm-turboquant` become an active validation target.
