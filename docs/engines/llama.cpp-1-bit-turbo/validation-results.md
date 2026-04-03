# llama.cpp-1-bit-turbo — Validation Results

**Last Updated:** 2026-04-02  
**Status:** Validated as the PrismML-style 1-bit reference and Bonsai benchmark track  
**Engine Role:** 1-bit reference path and benchmark source for Bonsai models, separate from the active `llama-turboquant` track

---

## Summary

This engine track captures the PrismML-style `Q1_0` / `Q1_0_G128` port and the
resulting Bonsai GPU performance data.

Validated results already recorded in THOTH show:

- PrismML `Q1_0` and `Q1_0_G128` type support is working
- Bonsai `1.7B`, `4B`, and `8B` load successfully after the type-remap fix
- GPU benchmarks on RX 6700 XT were captured for all three models
- Combined `Q1_0` weights plus TurboQuant K-cache behavior was measured

Important scope note:

- this file is the right place for the Bonsai benchmark matrix
- it is not the same runtime track as `llama-turboquant`
- llama-side OpenCoder speculative decoding and `llama-server` results belong in
  [`../llama-turboquant/validation-results.md`](../llama-turboquant/validation-results.md)

---

## Validated Capabilities

### Q1 Port

Validated outcomes:

- PrismML type-ID conflict resolved through remap-compatible port
- Bonsai 1-bit files now load successfully
- coherent output confirmed after port

Primary evidence:

- [`q1_0-port-results.md`](./q1_0-port-results.md)

### Bonsai GPU Benchmarks

Validated benchmark coverage:

- `Bonsai-1.7B`
- `Bonsai-4B`
- `Bonsai-8B`

Primary evidence:

- [`gpu-benchmark-results.md`](./gpu-benchmark-results.md)

Recorded averaged benchmark values:

| Model | pp512 (t/s) | tg128 (t/s) |
|------|-------------|-------------|
| Bonsai-1.7B | `2096.87` | `75.60` |
| Bonsai-4B | `856.64` | `120.66` |
| Bonsai-8B | `453.90` | `91.56` |

### Historical TurboQuant Comparison

This track also contains the earlier measured `Q1_0` plus TurboQuant K-cache
comparison:

| Model | Config | tg128 (t/s) |
|------|--------|-------------:|
| Bonsai-4B | baseline | `119.44` |
| Bonsai-4B | `tq3_0` K-cache | `114.92` |

### Monitored 2026-04-02 Rerun On `llama-turboquant`

The fresh monitored rerun was executed on the current `llama-turboquant` Docker
binary, not this older reference engine. It is still relevant here because it
shows what the current THOTH runtime does with all three Bonsai models under
live resource sampling.

| Model | Prompt t/s | Gen t/s | Context MiB | Unaccounted MiB | Peak VRAM GiB | Peak Docker Mem GiB | Peak CPU % | Peak Junction C |
|------|-----------:|--------:|------------:|----------------:|--------------:|--------------------:|-----------:|----------------:|
| Bonsai-1.7B | 1.8 | 1.4 | 56 | 221 | 1.95 | 7.21 | 1210.10 | 47 |
| Bonsai-4B | 0.7 | 0.6 | 72 | 206 | 1.98 | 7.74 | 1221.67 | 47 |
| Bonsai-8B | 0.4 | 0.3 | 72 | 220 | 1.99 | 8.82 | 1217.26 | 44 |

Monitored rerun evidence:
- [`20260402T094819_bonsai_cli_matrix_summary.json`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094819_bonsai_cli_matrix_summary.json)
- [`20260402T094819_bonsai17_cli.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094819_bonsai17_cli.log)
- [`20260402T094901_bonsai4_cli.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T094901_bonsai4_cli.log)
- [`20260402T095042_bonsai8_cli.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T095042_bonsai8_cli.log)

Interpretation:

- the original PrismML reference track remains the correct source for the strong
  Bonsai throughput numbers
- the current `llama-turboquant` runtime is functionally compatible with all
  three Bonsai models, but the monitored rerun shows it is heavily CPU-bound and
  far slower than the dedicated reference track

### Combined 1-bit + TurboQuant Cache Testing

Validated in this track:

- `Q1_0_G128` model weights with TurboQuant K-cache path
- measured impact of `tq3_0` K-cache relative to fp16 cache

Primary evidence:

- [`gpu-benchmark-results.md`](./gpu-benchmark-results.md)

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| Q1_0 port | ✅ | Port validated |
| Bonsai 1-bit loading | ✅ | All three models covered |
| GPU benchmark coverage | ✅ | 1.7B / 4B / 8B captured |
| TurboQuant cache comparison | ✅ | K-cache path measured |
| True EAGLE runtime | ❌ | Not the target of this engine |

---

## Operational Notes

- This engine is a validated 1-bit and benchmark reference, not the active path
  for true EAGLE.
- It remains useful for:
  - Bonsai performance baselines
  - Q1 compatibility reference
  - comparison against current `llama-turboquant` monitored reruns
  - comparison against SGLang once speculative decoding is stable there

---

## Next Step

Keep this engine as a benchmark and compatibility record. Active speculative
decoding and EAGLE work should continue in the SGLang track.
