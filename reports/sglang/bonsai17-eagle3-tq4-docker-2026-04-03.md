# Bonsai 1.7B Local EAGLE3 + `tq4` Docker Validation

Date: `2026-04-03`  
Engine: `sglang`  
Environment: `thoth` Docker container  
Path: `Bonsai-1.7B.gguf + local EAGLE3 draft + --kv-cache-dtype tq4 + Triton + radix`

## Result

Validated.

| Check | Result | Evidence |
|------|--------|----------|
| server boot | ✅ | [`20260403T070500_bonsai17_eagle3_tq4_typefix2.log`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2.log) |
| `/model_info` | ✅ | same log |
| `/generate` | ✅ | [`20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json) |
| Triton active | ✅ | same log |
| radix active | ✅ | same log |
| `tq4` active on target and draft | ✅ | same log |

## Short Response

Prompt tokens: `5`  
Completion tokens: `24`  
Latency: `158.24s`

Text:

```text
Alex, and I'm a student at the University of California, Berkeley. I'm interested in studying the history of science
```

Speculative metrics:

- `spec_accept_rate=0.0`
- `spec_draft_token_num=69`
- `spec_verify_ct=23`

## Peak Sampled Resources

- container memory: `8.52 GiB`
- GPU edge: `47 C`
- GPU junction: `50 C`
- VRAM allocation: `97%`

## Critical Fixes Behind This Validation

- GGUF type-name handling was corrected so unquantized norm weights load as standard weights instead of being misclassified as quantized `qweight` tensors
- Bonsai draft projection input is now coerced to the draft projection dtype before `self.fc`, preventing the `float != c10::Half` failure that had been blocking draft extend

## Artifacts

- [`20260403T070500_bonsai17_eagle3_tq4_typefix2.log`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2.log)
- [`20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_response.json)
- [`20260403T070500_bonsai17_eagle3_tq4_typefix2_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T070500_bonsai17_eagle3_tq4_typefix2_resources.jsonl)
