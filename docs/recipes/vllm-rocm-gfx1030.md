# vLLM ROCm Build Recipe (v0.16.1)

```bash
#!/bin/bash
# build.sh — Build vLLM from source for ROCm gfx1030 (AMD RX 6700 XT)
# See BUILD_RECIPE.md for full documentation.
#
# Usage:
#   cd /home/local/Projects/REPLICATOR
#   ./builds/vllm-v0.16.1-rocm/build.sh
#
# IMPORTANT: HIP compilation is memory-intensive (~3GB per hipcc process).
# MAX_JOBS is capped at 8 to avoid OOM on a 62GB system.

set -euo pipefail

PROJECT_ROOT="/home/local/Projects/REPLICATOR"
SOURCE_DIR="/home/local/Projects/.source"
VLLM_SRC="$SOURCE_DIR/vllm"
VENV_DIR="$PROJECT_ROOT/servers/vllm/.venv"
PYTHON="$VENV_DIR/bin/python"
VLLM_VERSION="${VLLM_VERSION:-v0.15.1}"

echo "═══ vLLM ROCm Build (gfx1030) ═══"
echo "Project:  $PROJECT_ROOT"
echo "Source:   $VLLM_SRC"
echo "Venv:     $VENV_DIR"
echo "Version:  $VLLM_VERSION"
echo ""

# --- Step 1: Create venv ---
echo "1/7 Creating Python 3.12 venv..."
if [ ! -f "$PYTHON" ]; then
  rm -rf "$VENV_DIR"
  uv venv "$VENV_DIR" --seed --system-site-packages --python 3.12
fi
echo "  ✓ venv ready"
echo ""

# --- Step 2: Clone vLLM ---
echo "2/7 Cloning vLLM $VLLM_VERSION..."
if [ ! -d "$VLLM_SRC" ]; then
  git clone --branch "$VLLM_VERSION" https://github.com/vllm-project/vllm.git "$VLLM_SRC"
else
  echo "  ✓ Source exists at $VLLM_SRC (skipping clone)"
fi
# Unshallow if needed (setuptools_scm requires full history)
cd "$VLLM_SRC"
if git rev-parse --is-shallow-repository 2>/dev/null | grep -q true; then
  echo "  Unshallowing..."
  git fetch --unshallow
fi
echo ""

# --- Step 3: Set environment ---
echo "3/7 Setting build environment..."
export HSA_OVERRIDE_GFX_VERSION=10.3.0
export PYTORCH_ROCM_ARCH="gfx1030"
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export VLLM_TARGET_DEVICE=rocm
export BUILD_FA="0"      # Disable CK Flash Attention (gfx1030 incompatible)
export BUILD_TRITON="1"  # Enable Triton Flash Attention (RDNA support)

# CRITICAL: Limit parallel HIP compilations to prevent OOM.
# Each hipcc process uses ~3GB RAM. 8 × 3GB = 24GB, safe on a 62GB system.
export MAX_JOBS=8

echo "  PYTORCH_ROCM_ARCH=$PYTORCH_ROCM_ARCH"
echo "  BUILD_FA=$BUILD_FA"
echo "  BUILD_TRITON=$BUILD_TRITON"
echo "  MAX_JOBS=$MAX_JOBS"
echo "  ✓ environment set"
echo ""

# --- Step 4: Install build deps ---
# IMPORTANT: Do NOT install torch here. It is bridged from the system via --system-site-packages.
echo "4/7 Installing build dependencies..."
$PYTHON -m pip install -q cmake ninja "packaging>=24.2" "setuptools>=77.0.3,<80.0.0" setuptools-scm wheel
echo "  ✓ deps installed"

# Verify torch is still the ROCm version (not overwritten by CUDA torch)
HIP_VERSION=$($PYTHON -c "import torch; print(torch.version.hip or 'NONE')")
if [ "$HIP_VERSION" = "NONE" ]; then
  echo "  ✗ FATAL: torch.version.hip is None — CUDA torch leaked into the venv!"
  echo "  Delete the venv and re-run this script."
  exit 1
fi
echo "  ✓ torch ROCm bridge intact (hip: $HIP_VERSION)"
echo ""

# --- Step 5: Build vLLM from source ---
# --no-deps: CRITICAL to prevent pip from pulling CUDA torch from PyPI.
# --no-build-isolation: Use the venv's packages (including system torch).
echo "5/7 Building vLLM (this will take 20-35 minutes)..."
cd "$VLLM_SRC"
$PYTHON -m pip install -v -e . --no-build-isolation --no-deps 2>&1 | tee /tmp/vllm_build.log
echo "  ✓ build complete"
echo ""

# --- Step 6: Install runtime deps (excluding torch) ---
echo "6/7 Installing runtime dependencies..."
$PYTHON -m pip install -q amdsmi
# Install other vLLM deps that --no-deps skipped, but exclude torch
$PYTHON -m pip install -q \
  aiohttp anthropic blake3 cachetools cbor2 cloudpickle compressed-tensors \
  depyf diskcache einops fastapi filelock gguf grpcio msgspec \
  numba numpy openai pydantic pyzmq ray requests sentencepiece \
  tiktoken tokenizers transformers tqdm uvicorn xgrammar lark \
  --no-deps 2>/dev/null || true
echo "  ✓ runtime deps installed"
echo ""

# --- Step 7: Verify ---
echo "═══ Verification ═══"
HSA_OVERRIDE_GFX_VERSION=10.3.0 $PYTHON -c "
import torch; print('torch:', torch.__version__)
print('hip:', torch.cuda.is_available())
try:
    import vllm._rocm_C; print('_rocm_C: OK ✓')
except ImportError as e:
    print('_rocm_C: FAILED ✗', e)
try:
    import vllm._C; print('_C: OK ✓')
except ImportError as e:
    print('_C:', e)
from vllm.config.device import DeviceConfig
print('device:', DeviceConfig().device_type)
"
echo ""
echo "═══ Done ═══"
echo "Build log: /tmp/vllm_build.log"
```
