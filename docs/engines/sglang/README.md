# SGLang — Engine Notes

**Status:** Not yet tested
**Fork:** `THOTH/forks/sglang` (carlosfundora/sglang)
**Upstream PR:** sgl-project/sglang#21628 (AMD TurboQuant branch)

---

## Plan

1. Fetch upstream PR #21628 (`turboquant-amd` branch)
2. Build with ROCm/HIP for gfx1030
3. Test TurboQuant KV cache integration
4. Compare with llama-turboquant results

## Prerequisites
- llama-turboquant proof-of-life (Track 1) must succeed first
- SGLang requires PyTorch ROCm — verify torch version compatibility

## Notes
- SGLang has the cleanest modular architecture for AMD TurboQuant port
- This is attack-order position #3 (after llama-turboquant and turboquant_plus)
