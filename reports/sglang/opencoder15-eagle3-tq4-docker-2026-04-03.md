# OpenCoder 1.5B Local EAGLE3 + `tq4` Docker Validation

Date: `2026-04-03`  
Engine: `sglang`  
Environment: `thoth` Docker container  
Path: `OpenCoder-1.5B-Instruct + local EAGLE3 draft + --kv-cache-dtype tq4 + Triton + radix`

## Result

Validated.

| Check | Result | Evidence |
|------|--------|----------|
| server boot | ✅ | [`20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270.log`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270.log) |
| `/model_info` | ✅ | same log |
| `/generate` | ✅ | [`20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json) |
| Triton active | ✅ | same log |
| radix active | ✅ | same log |
| `tq4` active | ✅ | same log |

## Short Response

Prompt tokens: `13`  
Completion tokens: `8`  
Latency: `131.27s`

Text:

```text
Write a test for this function using the
```

Speculative metrics:

- `spec_accept_rate=0.0`
- `spec_draft_token_num=21`
- `spec_verify_ct=7`

## Peak Sampled Resources

- container memory: `9.85 GiB`
- GPU junction: `52 C`
- VRAM allocation: `62%`

## Artifacts

- [`20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270.log`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270.log)
- [`20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_response.json)
- [`20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T043111_opencoder15w_eagle3_tq4_ctx1k_short_p270_resources.jsonl)
