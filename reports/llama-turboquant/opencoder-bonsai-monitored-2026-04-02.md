# OpenCoder + Bonsai Monitored Rerun — 2026-04-02

Source: `/home/local/Projects/THOTH/logs/hephaestion/20260402T094137_llama_matrix_summary.json`

## OpenCoder Monitored Matrix

| Config | Prompt (t/s) | Generation (t/s) | Context MiB | Peak VRAM | Peak Docker Mem | Peak CPU | Peak Junction |
|------|-------------:|-----------------:|------------:|----------:|----------------:|---------:|--------------:|
| 1.5B baseline | 188.1 | 124.1 | 210 | 2.27 GiB | 2.79 GiB | 1204.38% | 42 C |
| 1.5B `tq3_0` K-only | 74.2 | 126.6 | 127 | 2.30 GiB | 2.79 GiB | 1208.96% | 43 C |
| 1.5B `tq3_0` V-only | 47.6 | 3.1 | 127 | 3.81 GiB | 3.04 GiB | 1201.21% | 44 C |
| 1.5B `q8_0` V-only | 56.5 | 3.7 | 160 | 3.82 GiB | 3.04 GiB | 1237.62% | 44 C |
| 8B baseline | 349.5 | 54.7 | 128 | 6.39 GiB | 7.42 GiB | 1211.92% | 44 C |
| 8B `tq3_0` V-only | 37.5 | 1.6 | 78 | 6.72 GiB | 7.43 GiB | 1209.37% | 45 C |
| 8B + 1.5B draft | 384.5 | 47.8 | 128 | 8.41 GiB | 7.32 GiB | 1201.83% | 60 C |
| 8B + 1.5B draft + `tq3_0` V-cache | 43.7 | 3.7 | 78 | 8.23 GiB | 7.54 GiB | 1204.82% | 46 C |

## Bonsai Monitored Matrix

| Model | Prompt (t/s) | Generation (t/s) | Context MiB | Peak VRAM | Peak Docker Mem | Peak CPU | Peak Junction |
|------|-------------:|-----------------:|------------:|----------:|----------------:|---------:|--------------:|
| Bonsai-1.7B | 1.8 | 1.4 | 56 | 1.95 GiB | 7.21 GiB | 1210.10% | 47 C |
| Bonsai-4B | 0.7 | 0.6 | 72 | 1.98 GiB | 7.74 GiB | 1221.67% | 47 C |
| Bonsai-8B | 0.4 | 0.3 | 72 | 1.99 GiB | 8.82 GiB | 1217.26% | 44 C |

## Readout

- Draft-model speculation still works on llama.
- The 2026-04-02 V-cache reruns were much slower than the older historical
  record.
- Bonsai is compatible, but this runtime path is strongly CPU-bound.
