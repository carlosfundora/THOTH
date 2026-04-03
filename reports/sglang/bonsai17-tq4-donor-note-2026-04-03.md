# Bonsai 1.7B `tq4` Donor Note

Date: `2026-04-03`  
Target: `Bonsai-1.7B GGUF + local EAGLE3 draft + tq4 + Triton + radix`  
Problem: first real request aborts in the TurboQuant packed-KV path with `indexSelectSmallIndex ... Half`

## Decision

The fix direction should be:

- `packed-page write discipline`
- `quantized-page ownership/layout`
- `host-authoritative staging before device write`

Primary source of truth: [`dendrite`](/home/local/Projects/THOTH/forks/dendrite)

## Why Dendrite Is The Right Runtime Donor

Dendrite is the only donor in the local fork set that treats TurboQuant as a
first-class cache storage format instead of a post-hoc packed row written back
into a flat buffer.

Relevant evidence:

- [`README.md`](/home/local/Projects/THOTH/forks/dendrite/README.md)
  - states that Dendrite operates directly on quantized indices via `PageFormat::TurboQuant4Bit`
- [`paged.rs`](/home/local/Projects/THOTH/forks/dendrite/crates/dendrite-core/src/cache/paged.rs)
  - defines `PageFormat::TurboQuant4Bit`
  - stores packed indices in `data`
  - stores norms separately in `norms`
  - uses page-local layout instead of flattening K/V payloads into one row-major byte blob

The important structural difference is:

- current SGLang path:
  - compress K/V into flat per-token rows
  - write those rows back into a flat `uint8` KV pool
  - rely on device-side indexing and row placement during request-time extend
- Dendrite path:
  - allocate quantized pages directly in the target storage shape
  - keep indices and norms as explicit runtime-owned tensors
  - treat quantized storage as the native cache layout, not a transient serialization format

That is the pattern most aligned with the current Bonsai failure.

## Supporting Donors

### `turboquant_plus`

Relevant evidence:

- [`kv_cache.py`](/home/local/Projects/THOTH/forks/turboquant_plus/turboquant/kv_cache.py)
- [`test_kv_cache.py`](/home/local/Projects/THOTH/forks/turboquant_plus/tests/test_kv_cache.py)

What it contributes:

- K and V are not interchangeable objectives
- K uses the inner-product-preserving path
- V uses the MSE-oriented path
- compressed storage is treated as structured quantization metadata, not opaque raw bytes

This is useful as the algorithm donor, but not as the runtime-layout donor.

### `llama-turboquant`

Relevant evidence:

- [`llama-context.cpp`](/home/local/Projects/THOTH/forks/llama-turboquant/src/llama-context.cpp)
- [`llama-kv-cache.cpp`](/home/local/Projects/THOTH/forks/llama-turboquant/src/llama-kv-cache.cpp)

What it contributes:

- quantized V cache is explicitly guarded behind flash attention
- KV cache storage is backend-owned and buffer-oriented, not rewritten through arbitrary Python-side advanced indexing
- the proven Bonsai HIP path on this machine is a reminder to avoid fragile GPU-side indexing tricks during cache writes

This is the HIP guardrail donor, not the main layout donor.

## Chosen Implementation Direction

Do not keep iterating on the current flat-row packed write path in
[`memory_pool.py`](/home/local/Projects/THOTH/forks/sglang/python/sglang/srt/mem_cache/memory_pool.py).

Replace it with a Dendrite-style structured quantized cache layout on the HIP
TurboQuant path:

1. Split packed indices and norms into distinct storage tensors.
2. Store them in an explicit page/head/token layout instead of a flat per-row blob.
3. Stage packed data on CPU first on HIP.
4. Perform contiguous device copies into the final structured buffers.
5. Avoid request-time advanced indexing on packed `uint8` cache rows.

## What This Means For The Next Patch

The next runtime patch should target:

- [`memory_pool.py`](/home/local/Projects/THOTH/forks/sglang/python/sglang/srt/mem_cache/memory_pool.py)

Specifically:

- stop treating `k_buffer` and `v_buffer` as flat `uint8` row stores on the HIP `tq4` path
- add a HIP-specific structured storage path for:
  - packed indices
  - per-token norms
- keep the current CPU compression fallback as the staging step
- change the final write to contiguous page/head/token slices

## Non-Chosen Options

- `asymmetric K/V handling` as the primary fix:
  - relevant for quality and some backend constraints
  - not the best explanation for the current abort boundary
- `more debug logging`:
  - not useful now
  - the failure location is already bounded tightly enough
- `more GPU-side index_copy / gather variations`:
  - this is the failure family we should be exiting, not refining
