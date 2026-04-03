# OpenCoder Baseline — 2026-04-02

Source: `/home/local/Projects/THOTH/forks/sglang`

## Result

| Check | Result | Evidence |
|------|--------|----------|
| OpenCoder 8B server boot | ✅ | [`20260402T110300_sglang_opencoder8b_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log) |
| `/health` | ✅ | same log |
| First `/generate` | ✅ | same log |

## Notes

- This is the current reference-good SGLang ROCm path in THOTH.
- The request completed with `POST /generate` `200`.
- Fresh resource sampling is in:
  [`20260402T110300_sglang_opencoder8b_baseline_resources.jsonl`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline_resources.jsonl)

## Output Snapshot

- prompt tokens: `14`
- completion tokens: `64`
- end-to-end latency: `68.02s`

Primary evidence:

- [`20260402T110300_sglang_opencoder8b_baseline.log`](/home/local/Projects/THOTH/logs/hephaestion/20260402T110300_sglang_opencoder8b_baseline.log)
