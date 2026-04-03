# Vulkan Backend — Validation Results

**Last Updated:** 2026-04-02  
**Status:** Source present, not compiled  
**Engine Role:** Potential fallback or comparison backend for llama-side inference

---

## Summary

No Vulkan validation run has been completed yet.

This file is a tracking ledger for the backend, not evidence of a completed
validation.

The THOTH workspace contains the Vulkan source path under the llama-side stack,
but this backend has not been compiled or benchmarked in the current campaign.

Primary planning evidence:

- [`README.md`](./README.md)

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| Source presence | ✅ | Vulkan source tree exists |
| Docker build with `GGML_VULKAN=ON` | ⏳ | not yet attempted |
| HIP vs Vulkan comparison | ⏳ | not yet attempted |
| Benchmark capture | ⏳ | not yet attempted |

---

## Planned Validation

When this track becomes active, the minimum validation set is:

1. add `-DGGML_VULKAN=ON` to the Docker build
2. rebuild the image and runtime artifacts
3. run the same model set used for HIP comparison
4. record performance and behavior deltas against HIP

---

## Blocking Condition

Vulkan is not currently the active path because:

- HIP already provides the primary proof path on this machine
- speculative decoding and true EAGLE work are higher-priority blockers
- SGLang remains the active engine target for the next substantive work
