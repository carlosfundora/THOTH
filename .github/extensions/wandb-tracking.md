---
name: wandb-tracking
description: >
  W&B experiment tracking for THOTH TurboQuant research. Use this skill when
  logging inference benchmarks, KV compression ratios, VRAM measurements, or
  comparing TurboQuant vs baseline runs. The local W&B server runs at
  http://localhost:8765 — no cloud account or API key needed.
  Trigger phrases: "log this run", "track experiment", "compare runs",
  "save benchmark", "wandb", "experiment results", "VRAM delta", "tokens/sec".
---

# THOTH W&B Experiment Tracking

## Environment

- **Python runtime**: `docker compose exec thoth python3` (inside THOTH container)
- **W&B server**: `http://localhost:8765` (wandb-server Docker service)
- **SDK source**: `/workspace/thoth/forks/wandb` (installed editable on first run)
- **Project name**: `thoth-turboquant`

## Quick Setup (first time only)

```bash
# Inside THOTH container — install wandb SDK from fork source
docker compose exec thoth bash -c "pip install -e /workspace/thoth/forks/wandb --quiet"

# Login to local server (no API key needed for local)
docker compose exec thoth bash -c "wandb login --host=http://wandb-server:8080 --relogin"
```

## Standard THOTH Experiment Log Pattern

Every inference run should log these metrics:

```python
import wandb
import subprocess, re

def log_thoth_run(config: dict, result_log: str):
    """Log a THOTH inference benchmark to local W&B server."""
    wandb.init(
        project="thoth-turboquant",
        config=config,
        # config keys: model, kv_dtype (baseline/turbo4/turbo3/turbo2),
        #              n_gpu_layers, context_size, quantization, gpu_target
    )

    # Parse tokens/sec from llama-cli output
    tps_match = re.search(r"eval time.*?(\d+\.\d+) tokens/s", result_log)
    tokens_per_sec = float(tps_match.group(1)) if tps_match else 0

    # Get VRAM usage via rocm-smi
    vram_result = subprocess.run(
        ["rocm-smi", "--showmeminfo", "vram", "--json"],
        capture_output=True, text=True
    )

    wandb.log({
        "tokens_per_sec": tokens_per_sec,
        "kv_dtype": config.get("kv_dtype", "baseline"),
        "model": config.get("model"),
        "n_gpu_layers": config.get("n_gpu_layers"),
    })
    wandb.finish()
```

## Comparing Baseline vs TurboQuant

```python
import wandb
api = wandb.Api(api_key="local", base_url="http://localhost:8765")

runs = api.runs("thoth-turboquant")
baseline = [r for r in runs if r.config.get("kv_dtype") == "baseline"]
turbo4   = [r for r in runs if r.config.get("kv_dtype") == "turbo4"]

for b, t in zip(baseline, turbo4):
    tps_delta = t.summary["tokens_per_sec"] - b.summary["tokens_per_sec"]
    print(f"{b.config['model']}: {tps_delta:+.1f} t/s | "
          f"TQ overhead: {tps_delta/b.summary['tokens_per_sec']*100:.1f}%")
```

## W&B SDK Helper Functions

The `wandb-primary` skill in `forks/wandb-skills/skills/wandb-primary/scripts/`
provides reusable helpers:

```python
import sys
sys.path.insert(0, "/workspace/thoth/forks/wandb-skills/skills/wandb-primary/scripts")
from wandb_helpers import runs_to_dataframe, diagnose_run, compare_configs
```

- `runs_to_dataframe(runs)` — converts runs to pandas DataFrame for analysis
- `diagnose_run(run)` — prints quick diagnostic summary of a run
- `compare_configs(run1, run2)` — side-by-side config diff

## Key Gotchas

| Issue | Fix |
|-------|-----|
| `wandb: ERROR` on login | Use `--host=http://wandb-server:8080` (internal Docker network name) |
| SDK not found | `pip install -e /workspace/thoth/forks/wandb` |
| Dashboard not loading | Check `docker compose ps wandb-server` — must be healthy |
| Offline runs not syncing | `wandb sync .wandb/` inside container |
| VRAM reading fails | Run `rocm-smi --showmeminfo vram` as root or with video group |

## Circuit Breaker Reminder

When running GPU experiments, always monitor on the host:
```bash
watch -n 2 rocm-smi        # Terminal A — GPU temp + VRAM
radeontop -d -              # Terminal B — real-time utilization
```
**Abort if edge temp > 90°C.** Emergency stop: `~/thoth-kill.sh`
