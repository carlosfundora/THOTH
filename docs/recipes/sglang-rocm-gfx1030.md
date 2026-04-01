# SGLang ROCm Build Recipe (v0.5.9)

> Home > `builds/sglang-v0.5.9-rocm` > Build Recipe

## Prerequisites

- ROCm 7.2 installed in `/opt/rocm`
- `ninja-build`

## Build Steps

### 1. Create the venv

```bash
cd /home/local/Projects/REPLICATOR
uv venv "servers/sglang/.venv" --seed --system-site-packages --python 3.12
```

### 2. Apply consumer patches

```bash
cd /home/local/Projects/builds/sglang-v0.5.9-rocm/src/sgl-kernel
HSA_OVERRIDE_GFX_VERSION=10.3.0 \
AMDGPU_TARGET=gfx1030 \
python setup_rocm.py install
```

### 3. Install SGLang edible + HIP extras

```bash
cd ..
rm -f python/pyproject.toml && mv python/pyproject_other.toml python/pyproject.toml
pip install -e "python[all_hip]"
```

## Verification

```bash
HSA_OVERRIDE_GFX_VERSION=10.3.0 servers/sglang/.venv/bin/python -c "
import sglang; print('sglang:', sglang.__version__)
import torch; print('torch:', torch.__version__)
print('hip:', torch.cuda.is_available())
"
```

---
**Last Updated**: 2026-03-14
