# OpenCoder 1.5B Baseline Fault — 2026-04-02

## Result

The matched non-EAGLE baseline request is still unstable on ROCm in this SGLang fork.

Validated path:

- target: `OpenCoder-1.5B-Instruct`
- engine: `SGLang`
- backend: `triton`
- no speculative draft

## What Worked

- server boot succeeded
- `/health` returned `200`

## Failure

The first real `/generate` request aborted with:

- `HSA_STATUS_ERROR_EXCEPTION`
- kernel: `indexSelectSmallIndex ... Half`

This is the same ROCm-class failure family already seen in the unstable `tq4` and `STANDALONE` paths.

## Peak Resources Before Fault

| Metric | Value |
|---|---:|
| CPU `Tctl` | `61.8 C` |
| Host memory used | `45174 MB` |
| Container memory | `24.40 GiB` |
| GPU edge temperature | `48 C` |
| GPU junction temperature | `55 C` |
| GPU VRAM allocated | `56%` |
| GPU utilization | `90%` |

## Artifacts

- [`20260402T161900_opcoder15_baseline_generate_resources.jsonl`](/home/local/Projects/THOTH/logs/20260402T161900_opcoder15_baseline_generate_resources.jsonl)

## Notes

- This means the local EAGLE proof is currently stronger than the matched baseline path.
- The next baseline repair work should focus on the surviving ROCm `indexSelectSmallIndex` path, not on draft-asset availability.
