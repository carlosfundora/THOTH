# OpenCoder `tq4` — 2026-04-02

Source: `/home/local/Projects/THOTH/forks/sglang`

## Runtime Matrix

| Component | Version |
|------|---------|
| Python | 3.12.3 |
| PyTorch | 2.11.0+rocm7.2 |
| Triton | 3.6.0 |
| SGLang | 0.5.10rc0 |
| `sgl_kernel` | 0.4.0 |
| GPU target | gfx1030 via `HSA_OVERRIDE_GFX_VERSION=10.3.0` |

## Result

| Check | Result | Evidence |
|------|--------|----------|
| OpenCoder 8B + `tq4` server boot | ✅ | [`20260402T110500_sglang_opencoder8b_tq4_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T110500_sglang_opencoder8b_tq4_resources.jsonl) |
| `TurboQuant MHA KV Pool` init | ✅ | same resource capture |
| `/health` | ✅ | same resource capture |
| First `/generate` | ❌ | same resource capture |

## Current Blocker

- failure: `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`
- current write path still dies under the first real TurboQuant request

Primary evidence:

- [`20260402T110500_sglang_opencoder8b_tq4_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T110500_sglang_opencoder8b_tq4_resources.jsonl)
