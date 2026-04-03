# OpenCoder Draft Proof — 2026-04-01

Source: `/home/local/Projects/THOTH/forks/llama-turboquant`

## Result

| Check | Result | Evidence |
|------|--------|----------|
| Bonsai-1.7B GPU smoke | ✅ | [`20260401T212541_bonsai1.7b_q1_smoke.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212541_bonsai1.7b_q1_smoke.log) |
| OpenCoder-8B + 1.5B draft | ✅ | [`20260401T212631_opencoder_q4_speculative.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212631_opencoder_q4_speculative.log) |
| OpenCoder-8B + 1.5B draft + `tq3_0` V-cache | ✅ | [`20260401T212715_opencoder_q4_speculative_tq3v_fa.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212715_opencoder_q4_speculative_tq3v_fa.log) |
| `llama-server` health + completion | ✅ | [`20260401T212928_opencoder_q4_server_tq3v_fa.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T212928_opencoder_q4_server_tq3v_fa.log) |
| Invalid quantized V-cache path fails cleanly | ✅ | [`20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log`](/home/local/Projects/THOTH/logs/hephaestion/20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log) |

## OpenCoder Metrics

| Config | Prompt (t/s) | Generation (t/s) | Notes |
|------|-------------:|-----------------:|-------|
| 8B + 1.5B draft | 390.1 | 50.6 | plain draft-model speculation |
| 8B + 1.5B draft + `tq3_0` V-cache | 267.9 | 37.9 | `--flash-attn on` required |

## Boundary

This was ordinary llama draft-model speculation via `--model-draft`, not true
EAGLE.
