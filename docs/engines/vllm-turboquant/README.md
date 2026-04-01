# vLLM-TurboQuant — Engine Notes

**Status:** Not yet tested
**Fork:** `THOTH/forks/vllm-turboquant` (carlosfundora/vllm-turboquant)

---

## Plan

1. Install vllm-turboquant fork in container
2. Run `tests/quantization/test_turboquant.py`
3. Test serving with TurboQuant KV cache

## Prerequisites
- llama-turboquant and SGLang tracks should be validated first
- This is attack-order position #4 (lowest priority)

## Notes
- Fork already has 10 TurboQuant files (Triton kernels, backend, tests)
- Serving-focused — useful after proof-of-life is established
