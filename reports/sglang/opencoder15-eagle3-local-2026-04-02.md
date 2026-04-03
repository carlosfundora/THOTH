# OpenCoder 1.5B Local EAGLE3 — 2026-04-02

## Result

True `EAGLE3` is now confirmed locally in SGLang with a locally-built draft artifact.

Validated path:

- target: `OpenCoder-1.5B-Instruct`
- draft: `OpenCoder-1.5B-EAGLE3-local`
- engine: `SGLang`
- backend: `triton`
- device path: ROCm with `HSA_OVERRIDE_GFX_VERSION=10.3.0`

## What Worked

- SGLang launched with `--speculative-algorithm EAGLE3`
- the local draft loaded as `LlamaForCausalLMEagle3`
- `/health` returned `200`
- `/generate` returned `200`
- speculative metrics were present in the response

## Measured Request

Prompt:

`Write a three sentence summary of speculative decoding.`

Response summary:

| Metric | Value |
|---|---:|
| Completion tokens | `64` |
| End-to-end latency | `54.50 s` |
| Effective output rate | `1.17 tok/s` |
| Spec accept rate | `0.3333` |
| Spec accept length | `2.0` |
| Accepted draft tokens | `32` |
| Draft tokens proposed | `96` |

## Peak Resources

| Metric | Value |
|---|---:|
| CPU `Tctl` | `66.4 C` |
| Host memory used | `46398 MB` |
| Container memory | `24.83 GiB` |
| GPU edge temperature | `48 C` |
| GPU junction temperature | `60 C` |
| GPU VRAM allocated | `62%` |
| GPU utilization | `99%` |

## Artifacts

- [`20260402T161700_opcoder15_eagle3_generate_response.json`](/home/local/Projects/THOTH/logs/20260402T161700_opcoder15_eagle3_generate_response.json)
- [`20260402T161700_opcoder15_eagle3_generate_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T161700_opcoder15_eagle3_generate_resources.jsonl)
- [`opencoder-1.5b-eagle3-local.json`](/home/local/Projects/THOTH/forks/SpecForge/configs/opencoder-1.5b-eagle3-local.json)

## Notes

- The local draft was constructed directly from SpecForge config plus target embeddings.
- The output quality is not yet meaningful; this is a runtime proof artifact, not a trained draft.
- This proof removes “missing local EAGLE asset” as the current blocker.
