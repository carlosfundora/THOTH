# AITER ROCm Build Recipe (v0.1.10)

> Home > `builds/aiter-v0.1.10` > Build Recipe

## Build Steps

```bash
cd /home/local/Projects/builds/aiter-v0.1.10/src
HSA_OVERRIDE_GFX_VERSION=10.3.0 \
AMDGPU_TARGET=gfx1030 \
uv pip install -e . --no-deps
```

---
**Last Updated**: 2026-03-14
