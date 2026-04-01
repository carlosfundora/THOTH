# PyTorch from Source (ROCm gfx1030)

```bash
#!/bin/bash
set -e

# Define source and build directories
SOURCE_DIR="/home/local/Projects/.source/pytorch"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing PyTorch from source at $SOURCE_DIR..."

cd "$SOURCE_DIR"

# Use uv to install in editable mode without build isolation
# We use --break-system-packages because this is a user-local environment
# interacting with system python as configured in this dev environment.
# uv pip install --system failed due to permissions, and --user is not supported.
# Falling back to standard pip for user-local install.
# CMAKE_FRESH=1 is required because the source directory was moved.
# PYTORCH_ROCM_ARCH=gfx1030 is required for RX 6700 XT.
# Explicitly set missing ROCm library paths (missing symlinks in /opt/rocm).
# Set CMAKE_PREFIX_PATH to include local symlinks for missing ROCm libraries
export CMAKE_PREFIX_PATH=/home/local/Projects/dev-build/rocm-links

# Explicitly set ROCm compiler paths for fresh build environment
export ROCM_PATH=/opt/rocm-7.1.0
export PATH=$ROCM_PATH/bin:$PATH
export HIP_PATH=$ROCM_PATH
export CC=hipcc
export CXX=hipcc

# Required for RX 6700 XT detection
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# Limit concurrency to avoid OOM/System Freeze
export MAX_JOBS=8

# Explicitly help CMake find OpenMP (GCC implementation)
export CFLAGS="-fopenmp -I/usr/lib/gcc/x86_64-linux-gnu/12/include"
export CXXFLAGS="-fopenmp -I/usr/lib/gcc/x86_64-linux-gnu/12/include"
export LDFLAGS="-L/usr/lib/gcc/x86_64-linux-gnu/12"
# Force MKL-DNN to use OpenMP
export CMAKE_ARGS="-DOpenMP_C_FLAGS=-fopenmp -DOpenMP_CXX_FLAGS=-fopenmp -DOpenMP_C_LIB_NAMES=gomp -DOpenMP_CXX_LIB_NAMES=gomp -DOpenMP_gomp_LIBRARY=/usr/lib/gcc/x86_64-linux-gnu/12/libgomp.so"

PYTORCH_ROCM_ARCH=gfx1030 CMAKE_FRESH=1 pip install -e . --no-build-isolation --break-system-packages

echo "Installation complete."
echo "Verifying import..."
python3 -c "import torch; print(f'Torch version: {torch.__version__}'); print(f'Install path: {torch.__file__}')"
```
