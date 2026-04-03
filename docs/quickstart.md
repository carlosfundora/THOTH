# THOTH Quickstart

> Last updated: 2026-04-03
> Primary P-EAGLE target: `Bonsai-1.7B`

This is the shortest useful map of the THOTH environment: where the code lives, which Python environment is canonical, where the model artifacts live, where training data is expected, and which commands are the current source of truth for EAGLE-3 and P-EAGLE work.

## Project Root

- THOTH root: `/home/local/Projects/THOTH`
- Main branch: `main`

## Python Environments

- Primary shared ROCm environment: `/home/local/python/.venv-pytorch-rocm`
- Canonical live SGLang environment: `/home/local/Projects/THOTH/forks/sglang/.venv-sglang`
- SGLang must not be installed into the shared ROCm base venv; `.venv-sglang` bridges to it
- Preferred package manager against that venv:

```bash
uv pip install --python /home/local/python/.venv-pytorch-rocm/bin/python <package>
```

For local SGLang work, the supported entrypoint is:

```bash
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -m sglang.launch_server
```

For host-side P-EAGLE training, the supported interpreter is:

```bash
/home/local/python/.venv-pytorch-rocm/bin/python
```

## Runtime / Training Repos

- SGLang fork: `/home/local/Projects/THOTH/forks/sglang`
- SpecForge fork: `/home/local/Projects/THOTH/forks/SpecForge`
- standalone llama.cpp fork: `/home/local/Projects/THOTH/forks/llama.cpp`
- llama-turboquant fork: `/home/local/Projects/THOTH/forks/llama-turboquant`
- canonical EAGLE donor: `/home/local/Projects/THOTH/forks/EAGLE`
- canonical P-EAGLE training donor: `/home/local/Projects/THOTH/forks/speculators`
- production P-EAGLE serving donor: `/home/local/Projects/THOTH/forks/vllm`

## Build Resources

The following were intentionally moved out of `forks/` and into `build-resources/` because they are build/toolchain dependencies rather than active runtime forks.

- build resources root: `/home/local/Projects/THOTH/build-resources`
- TorchVision source: `/home/local/Projects/THOTH/build-resources/vision`
- PyTorch source: `/home/local/Projects/THOTH/build-resources/pytorch`
- Triton source: `/home/local/Projects/THOTH/build-resources/triton`
- flash-attention source: `/home/local/Projects/THOTH/build-resources/flash-attention`
- ROCm/AOT/Tensile sources:
  - `/home/local/Projects/THOTH/build-resources/aotriton`
  - `/home/local/Projects/THOTH/build-resources/hip`
  - `/home/local/Projects/THOTH/build-resources/rocBLAS`
  - `/home/local/Projects/THOTH/build-resources/rocm-libraries`
  - `/home/local/Projects/THOTH/build-resources/rocm-install-on-linux`
  - `/home/local/Projects/THOTH/build-resources/Tensile`
  - `/home/local/Projects/THOTH/build-resources/TheRock`

## Model Registry

Model artifacts are not stored under THOTH itself. They live under:

- model registry root: `/home/local/Projects/models/registry`

### Current local base models

- OpenCoder HF weights:
  - `/home/local/Projects/models/registry/infly/OpenCoder-1.5B-Instruct/weights`
- Bonsai runtime GGUF:
  - `/home/local/Projects/models/registry/PrismML/Bonsai-1.7B-gguf/Bonsai-1.7B.gguf`
- Public HF training targets used by the launcher:
  - `prism-ml/Bonsai-1.7B-unpacked`
  - `prism-ml/Bonsai-4B-unpacked`

### Current local EAGLE-3 warm-start heads

- OpenCoder EAGLE-3:
  - `/home/local/Projects/models/registry/local/OpenCoder-1.5B-EAGLE3-local/weights`
- Bonsai EAGLE-3:
  - `/home/local/Projects/models/registry/local/Bonsai-1.7B-EAGLE3-local/weights`

### Intended local P-EAGLE output locations

- OpenCoder P-EAGLE:
  - `/home/local/Projects/models/registry/local/OpenCoder-1.5B-P-EAGLE-local`
- Bonsai P-EAGLE:
  - `/home/local/Projects/models/registry/local/Bonsai-1.7B-P-EAGLE-local`

### Writable smoke artifact locations on this machine

`/home/local/Projects/models/registry/local` is currently owned by `root`, so new smoke checkpoints cannot be created there as the `local` user.

- writable THOTH-local artifact root:
  - `/home/local/Projects/THOTH/artifacts/models/local`
- validated Bonsai smoke checkpoint:
  - `/home/local/Projects/THOTH/artifacts/models/local/Bonsai-1.7B-P-EAGLE-local-smoke/epoch_0_step_2`

## Important Bonsai Note

The local Bonsai GGUF README and `NOTICE.txt` in:

- `/home/local/Projects/models/registry/PrismML/Bonsai-1.7B-gguf`

state that Bonsai-1.7B is built from `Qwen3-1.7B` dense.

That means:

- runtime inference target today: local Bonsai GGUF
- HF/Transformers training target should use Prism's unpacked release, not the GGUF:
  - `prism-ml/Bonsai-1.7B-unpacked`
- do not use the 1-bit GGUF itself for P-EAGLE training; it dequantizes away the whole point of the runtime artifact

## SpecForge Cache Locations

- SpecForge cache root: `/home/local/Projects/THOTH/forks/SpecForge/cache`
- processed datasets: `/home/local/Projects/THOTH/forks/SpecForge/cache/dataset`
- hidden states (offline training): `/home/local/Projects/THOTH/forks/SpecForge/cache/hidden_states`
- vocab mappings: `/home/local/Projects/THOTH/forks/SpecForge/cache/vocab_mapping`
- compiled kernels: `/home/local/Projects/THOTH/forks/SpecForge/cache/compiled_kernels`

As of 2026-04-03, THOTH does **not** have a prepared local ShareGPT/UltraChat JSONL checked in or cached yet. The launcher scripts below can prepare ShareGPT into the dataset cache if needed.

## Training Entry Points

### Core trainer

- SpecForge EAGLE/P-EAGLE trainer:
  - `/home/local/Projects/THOTH/forks/SpecForge/scripts/train_eagle3.py`

### P-EAGLE launcher

- New wrapper:
  - `/home/local/Projects/THOTH/forks/SpecForge/scripts/train_p_eagle.py`

This wrapper:

- warm-starts from a local EAGLE-3 head via `--ckpt-dir`
- forces `P_EAGLE` metadata (`parallel_drafting`, `k_train`, `cod_retention`, `mask_token_id`)
- uses THOTH’s local registry/cache defaults
- points Bonsai training at `prism-ml/Bonsai-1.7B-unpacked`
- can prepare ShareGPT automatically when the dataset file is missing
- runs a host preflight before launching training:
  - reports free RAM and GPU visibility
  - detects and stops competing `llama-server`, `sglang`, and THOTH/SpecForge training jobs
- supports a smoke profile that writes a sampled JSONL dataset for faster validation runs
- uses `sdpa` for Bonsai smoke training on this ROCm box
- supports a low-VRAM smoke mode that trains only `mask_hidden`

### Bonsai-first example launcher

- `/home/local/Projects/THOTH/forks/SpecForge/examples/run_bonsai_1.7b_p_eagle_online.sh`

## Quick Commands

### 1. Prepare ShareGPT locally

```bash
VENV=/home/local/python/.venv-pytorch-rocm
PATH="$VENV/bin:$PATH"

cd /home/local/Projects/THOTH/forks/SpecForge
"$VENV/bin/python" scripts/prepare_data.py \
  --dataset sharegpt \
  --output-path /home/local/Projects/THOTH/forks/SpecForge/cache/dataset
```

Expected output:

- `/home/local/Projects/THOTH/forks/SpecForge/cache/dataset/sharegpt_train.jsonl`

### 2. Launch Bonsai P-EAGLE fine-tuning from the local EAGLE-3 head

```bash
VENV=/home/local/python/.venv-pytorch-rocm
PATH="$VENV/bin:$PATH"

cd /home/local/Projects/THOTH/forks/SpecForge
"$VENV/bin/python" scripts/train_p_eagle.py \
  --profile bonsai17 \
  --prepare-data-if-missing
```

### 3. Launch the faster Bonsai smoke profile

```bash
VENV=/home/local/python/.venv-pytorch-rocm
PATH="$VENV/bin:$PATH"

cd /home/local/Projects/THOTH/forks/SpecForge
"$VENV/bin/python" scripts/train_p_eagle.py \
  --profile bonsai17_smoke \
  --prepare-data-if-missing \
  --output-dir /home/local/Projects/THOTH/artifacts/models/local/Bonsai-1.7B-P-EAGLE-local-smoke
```

Defaults for `bonsai17_smoke`:

- target model: `prism-ml/Bonsai-1.7B-unpacked`
- warm-start head: local `Bonsai-1.7B-EAGLE3-local`
- max length: `256`
- `k_train`: `5`
- `ttt_length`: `5`
- attention backend: `sdpa`
- low-VRAM smoke mode: `train_mask_hidden_only=true`
- max steps: `500`
- sampled dataset: first `1024` lines from ShareGPT
- allocator hint: `PYTORCH_ALLOC_CONF=expandable_segments:True`

## SGLang Install Provenance

- stale legacy user-local install to retire: `~/.local/bin/sglang`
- stale editable shim to retire: `~/.local/lib/python3.12/site-packages/__editable__.sglang-0.0.0.pth`
- canonical live `sglang` import after cutover resolves to:
  - `/home/local/Projects/THOTH/forks/sglang/python/sglang`
- current live `sgl_kernel` import still resolves to:
  - `/home/local/python/.venv-pytorch-rocm/lib/python3.12/site-packages/sgl_kernel`
- current live `triton` import still resolves to:
  - `/home/local/.local/lib/python3.12/site-packages/triton`
- local THOTH `sgl-kernel` source exists at:
  - `/home/local/Projects/THOTH/forks/sglang/sgl-kernel/python`
- but it is not yet the live imported kernel package because local rebuilds still fail against the current shared ROCm torch headers

See the current cutover and provenance audit:

- `/home/local/Projects/THOTH/reports/sglang/live-install-cutover-2026-04-03.md`

Verification commands:

```bash
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -c "import sglang; print(sglang.__file__)"
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -c "import sgl_kernel; print(sgl_kernel.__file__)"
```

### 4. Dry-run the resolved Bonsai command

```bash
VENV=/home/local/python/.venv-pytorch-rocm
PATH="$VENV/bin:$PATH"

cd /home/local/Projects/THOTH/forks/SpecForge
"$VENV/bin/python" scripts/train_p_eagle.py \
  --profile bonsai17_smoke \
  --prepare-data-if-missing \
  --dry-run
```

## Reports / Logs / Manifests

- logs: `/home/local/Projects/THOTH/logs`
- reports: `/home/local/Projects/THOTH/reports`
- manifests: `/home/local/Projects/THOTH/manifests`

Important recent runtime validations:

- OpenCoder local EAGLE-3:
  - `/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-local-2026-04-02.md`
  - `/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md`
- Bonsai local EAGLE-3:
  - `/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md`

## Current P-EAGLE Status

- local EAGLE-3 warm-start heads: available
- SpecForge P-EAGLE config/model support: implemented
- SGLang P-EAGLE checkpoint recognition: implemented
- local trained P-EAGLE smoke head: present at `/home/local/Projects/THOTH/artifacts/models/local/Bonsai-1.7B-P-EAGLE-local-smoke/epoch_0_step_2`
- smoke checkpoint reload through `AutoEagle3DraftModel.from_pretrained(...)`: validated
- primary target for first P-EAGLE training run: `Bonsai-1.7B`
