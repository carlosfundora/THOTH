# ═══════════════════════════════════════════════════════════════
# THOTH — ROCm 7.2 + TurboQuant Dev Environment
# Target: RX 6700 XT (gfx1031 → gfx1030 piggyback)
# ═══════════════════════════════════════════════════════════════
# Multi-stage: builder compiles llama-turboquant, runtime is lean
# ═══════════════════════════════════════════════════════════════

# ── Stage 1: Builder ────────────────────────────────────────────
FROM rocm/dev-ubuntu-24.04:7.2-complete AS builder

ARG GPU_TARGETS=gfx1030
ARG CMAKE_BUILD_TYPE=Release

ENV DEBIAN_FRONTEND=noninteractive \
    HSA_OVERRIDE_GFX_VERSION=10.3.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    pkg-config \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy llama-turboquant source for building
COPY forks/llama-turboquant /src/llama-turboquant

WORKDIR /src/llama-turboquant

RUN mkdir -p build && cd build && \
    HIPCXX="$(hipconfig -l)/clang" \
    HIP_PATH="$(hipconfig -R)" \
    cmake -S .. -B . \
      -G Ninja \
      -DGGML_HIP=ON \
      -DGPU_TARGETS=${GPU_TARGETS} \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=/opt/llama \
      -DGGML_TURBOQUANT=ON \
    && cmake --build . --config ${CMAKE_BUILD_TYPE} -j$(nproc) \
    && cmake --install .

# ── Stage 2: Runtime ────────────────────────────────────────────
FROM rocm/dev-ubuntu-24.04:7.2-complete AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    HIP_VISIBLE_DEVICES=0 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    vim \
    htop \
    rocm-smi \
    && rm -rf /var/lib/apt/lists/*

# Python ML stack (ROCm wheels)
RUN pip3 install --no-cache-dir --break-system-packages \
    torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/rocm7.2 && \
    pip3 install --no-cache-dir --break-system-packages \
    transformers \
    accelerate \
    safetensors \
    sentencepiece \
    huggingface-hub \
    tokenizers \
    datasets \
    bitsandbytes \
    peft \
    scipy \
    numpy \
    tqdm \
    requests

# Copy installed llama-turboquant from builder
COPY --from=builder /opt/llama/ /usr/local/
RUN ldconfig

# Workspace layout (matches docker-compose volume mounts)
RUN mkdir -p /workspace/thoth \
             /workspace/forks \
             /workspace/models \
             /workspace/build

WORKDIR /workspace

# Copy THOTH project files (small — manifests, scripts, configs)
COPY . /workspace/thoth/

EXPOSE 8080

# Default: interactive shell (override in docker-compose for servers)
CMD ["/bin/bash"]
