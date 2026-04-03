# SGLang Live Install Cutover — 2026-04-03

## Goal

Replace the stale user-local SGLang install with a canonical THOTH-owned runtime under:

- `/home/local/Projects/THOTH/forks/sglang/.venv-sglang`

while keeping the shared ROCm PyTorch stack in:

- `/home/local/python/.venv-pytorch-rocm`

## Result

The cutover is functionally complete for `sglang` itself.

- live `sglang` now imports from:
  - `/home/local/Projects/THOTH/forks/sglang/python/sglang/__init__.py`
- `python -m sglang.launch_server --help` works from:
  - `/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python`

## What changed

- rebuilt the broken root-owned `.venv-sglang` as a user-owned environment
- added a `.pth` bridge from `.venv-sglang` into:
  - `/home/local/python/.venv-pytorch-rocm/lib/python3.12/site-packages`
- installed local editable THOTH `sglang` into `.venv-sglang`
- retired the stale user-local editable SGLang shims:
  - `~/.local/bin/sglang`
  - `~/.local/lib/python3.12/site-packages/__editable__.sglang-0.0.0.pth`
  - `~/.local/lib/python3.12/site-packages/__editable___sglang_0_0_0_finder.py`
- normalized known external launchers to the absolute THOTH interpreter:
  - `/home/local/Projects/DEMERZEL/servers/sglang/server.sh`
  - `/home/local/Projects/ENCOM/DEMERZEL/servers/sglang/server.sh`

## Verified live provenance

- `sglang`:
  - `/home/local/Projects/THOTH/forks/sglang/python/sglang/__init__.py`
- `torch`:
  - `/home/local/python/.venv-pytorch-rocm/lib/python3.12/site-packages/torch/__init__.py`
- `sgl_kernel`:
  - `/home/local/python/.venv-pytorch-rocm/lib/python3.12/site-packages/sgl_kernel/__init__.py`
- `triton`:
  - `/home/local/.local/lib/python3.12/site-packages/triton/__init__.py`

## Deviation from the ideal target

The ideal target was:

- THOTH-local `sglang`
- THOTH-local `sgl-kernel`
- no reliance on stale or ambiguous user-local SGLang shims

The actual current live state is:

- THOTH-local `sglang`: yes
- THOTH-local `sgl-kernel`: no
- stale user-local SGLang executable/shim: retired

## Current blocker on THOTH-local `sgl-kernel`

Local THOTH `sgl-kernel` source exists at:

- `/home/local/Projects/THOTH/forks/sglang/sgl-kernel/python`

but it is not the live imported kernel package yet.

Observed blockers during rebuild attempts:

- editable install from `sgl-kernel/python` is not supported directly because that directory does not expose the expected standalone packaging entrypoint
- local extension build attempts fail against the current shared ROCm torch headers because those headers still pull CUDA-oriented includes such as:
  - `cuda_runtime_api.h`
  - `cublas_v2.h`
  - `cuda_bf16.h`
- a direct symlink to the local THOTH `sgl_kernel` package imports far enough to fail on unresolved native symbols instead of providing a working kernel module

Practical conclusion:

- the live stack should continue using the working base-wheel `sgl_kernel` for now
- local THOTH `sgl-kernel` promotion is a separate kernel/toolchain task, not part of this SGLang executable cutover

## Low-level tree audit

Audited local trees:

- clean:
  - `build-resources/aotriton`
  - `build-resources/hip`
  - `build-resources/rocBLAS`
  - `build-resources/rocm-libraries`
  - `build-resources/Tensile`
  - `build-resources/TheRock`
  - `forks/sglang/sgl-kernel`
- dirty:
  - `build-resources/triton`
  - `build-resources/pytorch`

Current evidence does **not** prove that the dirty local `build-resources/triton` or `build-resources/pytorch` trees are the active runtime source for the working SGLang/SpecForge path.

Current active runtime imports instead resolve to:

- `triton` from user site
- `torch` from the shared ROCm base venv

Therefore these dirty local low-level trees were **not** exported or promoted as part of the live SGLang cutover.

## Verification commands

```bash
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -c "import sglang; print(sglang.__file__)"
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -c "import sgl_kernel; print(sgl_kernel.__file__)"
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -c "import triton; print(triton.__file__)"
/home/local/Projects/THOTH/forks/sglang/.venv-sglang/bin/python -m sglang.launch_server --help
```
