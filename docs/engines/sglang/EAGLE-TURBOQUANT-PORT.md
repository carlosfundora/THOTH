# SGLang Port Progress: EAGLE3, TurboQuant & 1-bit GGUF Compatibility

**Status**: Historical snapshot, superseded by [`README.md`](./README.md) and [`validation-results.md`](./validation-results.md)
**Hardware Target**: AMD RDNA2 (gfx1030)
**Last Updated**: 2026-04-03

This document captures an earlier bring-up phase and is retained for historical
context only. It no longer reflects the current runtime truth.

Current source of truth:

- validated OpenCoder Docker path with `local EAGLE3 + tq4 + Triton + radix`
- validated Bonsai 1.7B Docker path with `local EAGLE3 + tq4 + Triton + radix`
- next target: simultaneous `EAGLE3` behavior on both the draft and generation models

See:

- [`README.md`](./README.md)
- [`validation-results.md`](./validation-results.md)
- [`/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md)
- [`/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md)

## 1. Context & Objectives
The goal of this porting session was to achieve a functioning SGLang environment on ROCm capable of utilizing speculative decoding (EAGLE3/STANDALONE) alongside TurboQuant KV cache compression (`tq4`), with explicit support for 1-bit PrismML/Bonsai quantized GGUF artifacts. 

## 2. Port Steps Completed & Stabilized

### Base Initialization
- Cherry-picked the TurboQuant donor commit (`96183598c`) cleanly onto the `sglang/main` fork.
- Cleanly committed the `llama.cpp` side patch (isolated to a single null-context guard to prevent downstream faults) before strictly continuing into the SGLang architecture.

### Build and Environment
- **ROCm Kernel Gate**: Patched `sgl-kernel/setup_rocm.py` to accept RDNA2 safely. Normalized `gfx1031` to `gfx1030` and explicitly disabled MI-only FP8 build paths. The artifact compiles and injects successfully into the venv.
- **Docker Purity**: SGLang natively defines CUDA-oriented package trees. Used targeted `uv --no-deps` to manually resolve pure-Python dependencies (e.g. pyzmq, einops, soundfile, _cffi_backend) inside the Docker container to achieve a clean CLI help trace without pulling CUDA binaries.
- **Config Fencing**: Modified the SGLang quantization registry to stop importing unneeded backends during config processing, successfully avoiding non-essential dependencies like `compressed_tensors`.

### GGUF & 1-Bit Enhancements
- **GGUF Compatibility Shim**: Upstream SGLang effectively ties its `gguf` reading implementations to CUDA/MUSA. Implemented `gguf_compat.py` (placed in `srt/utils/` to bypass mutual `model_loader` circular imports). 
- **Type Remapping**: The compatibility layout successfully catches the unknown 1-bit types and remaps them (e.g. from invalid `41` to `43`), preventing a type explosion prior to parsing.
- **CPU Bridge for Prism Q1**: To bypass an immediate GPU page-fault during dequantized tensor materialization on HIP, the port forces the `PRISM Q1` matmul path to utilize a CPU bridge (dequantize weight to CPU -> execute matmul -> move result), stabilizing 1-bit execution.

### JIT and JNA ROCm Fallbacks
- **Token ID JIT**: Blocked HIP from attempting to access TVM-backed bindings (`tvm_ffi`) inside `resolve_future_token_ids`. It now uses the native tensor fallback.
- **KV Cache JIT**: Switched `can_use_store_cache()` to unconditionally return `False` on HIP limits, avoiding the TVM fallback crashing SGLang caching.
- **TurboQuant MHA Write-Path**: Prevented the first speculative TurboQuant batch from faulting out by patching the MHA TurboQuant `tq4` store path, stripping away failing HIP advanced-index writes into packed uint8 buffers natively.

### Draft & Speculative Guards
- Added targeted validation tests to actively prevent missing EAGLE metadata from wasting loader cycles (e.g., throwing a fail-fast error when `eagle_config` is absent from plain instruct draft endpoints).

## 3. Immediate Diagnostics & Active Blocker
The live OpenCoder 8B (target) + 1.5B (draft) spec trace reaches target loading, allocates valid `tq4` cache, and correctly drops into draft generation.

**The Current Stall**: The HTTP path is frozen sitting on a `503`. Py-spy reveals that the stall is legitimate but looping inside the draft-model weight loading stage. The scheduler remains in an intensive boundary loop during speculative draft init, meaning the server doesn’t advance to Uvicorn binding.

## 4. Next Steps for Upcoming Session
1. Profile the scheduler-side stall during speculative draft bring-up.
2. If necessary, limit or reduce the draft-side loading profile directly to see if the boundary stall clears out.
3. Validate OpenCoder inference requests fully once health checks switch out of `503`.
