# OpenCoder `STANDALONE` — 2026-04-02

Source: `/home/local/Projects/THOTH/forks/sglang`

## Result

| Check | Result | Evidence |
|------|--------|----------|
| target model load | ✅ | [`20260402T111000_sglang_opencoder8b_standalone_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T111000_sglang_opencoder8b_standalone_resources.jsonl) |
| draft model load | ✅ | same resource capture |
| `/health` | ✅ | same resource capture |
| First `/generate` | ❌ | same resource capture |

## Current Blocker

- failure: `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`
- speculative runtime still fails on the first real request after startup

Primary evidence:

- [`20260402T111000_sglang_opencoder8b_standalone_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T111000_sglang_opencoder8b_standalone_resources.jsonl)
