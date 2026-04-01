# THOTH Attack Plan

> Goal: TurboQuant KV cache + speculative decoding on RX 6700 XT (gfx1031)
> Frozen 8B target (OpenCoder) + adaptive 1.5B draft (Medusa → EAGLE-3)
> Last updated: 2026-03-31

---

## Principle

Prove TurboQuant on gfx1031 in HIP llama.cpp first, harvest algorithm pieces from turboquant_plus and scos-lab, then port the format into SGLang or vLLM once quantization behaves on the hardware. That is the least stupid order of operations.

---

## Experiment 1: HIP llama.cpp First ⭐ START HERE

**Goal**: Prove TurboQuant runs at all on gfx1031.

**Fork**: `forks/llama-turboquant` (TheTom/llama-cpp-turboquant, branch `feature/turboquant-kv-cache`)

**Why first**: RX 6700 XT is explicitly listed in TheTom's build docs with `HSA_OVERRIDE_GFX_VERSION=10.3.0`. The RX 9070 XT success yesterday makes this the highest-confidence first experiment.

**Steps**:
```bash
# Inside THOTH Docker container
cd /workspace/thoth/forks/llama-turboquant

# Build (already done in Docker image, but can rebuild)
mkdir -p build && cd build
HSA_OVERRIDE_GFX_VERSION=10.3.0 \
HIPCXX="$(hipconfig -l)/clang" \
HIP_PATH="$(hipconfig -R)" \
cmake -S .. -B . \
  -DGGML_HIP=ON \
  -DGPU_TARGETS=gfx1030 \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_TURBOQUANT=ON
cmake --build . --config Release -j$(nproc)

# Test
./bin/llama-cli \
  --model /workspace/models/<opencoder-8b-q4.gguf> \
  --n-gpu-layers 99 \
  --kv-cache-dtype turbo4 \
  -p "test"
```

**Success criteria**:
- [ ] Binary compiles with GGML_TURBOQUANT=ON
- [ ] `rocm-smi` shows GPU memory allocated
- [ ] `--kv-cache-dtype turbo4` accepted without crash
- [ ] Output is coherent (not garbage)
- [ ] KV memory usage is visibly lower than baseline

**Failure modes to watch**:
- HIP aperture violation → check HSA_OVERRIDE is set
- `invalid device function` → ROCm version mismatch
- Garbage output → quantization drift, go to Experiment 2

---

## Experiment 2: Algorithm Validation on CPU

**Goal**: Separate algorithm validation from runtime validation. Verify rotation, codebook, outlier, and QJL behavior independently.

**Forks**:
- `forks/turboquant_plus` (Apache-2.0, safe to modify)
- scos-lab/turboquant (calibration data)

**Why**: Reduces the odds of spending two days blaming HIP for what is actually quantization drift.

**Steps**:
```bash
# CPU-only, no GPU needed
cd /workspace/thoth/forks/turboquant_plus

# Run test suite
python -m pytest tests/ -v

# Validate K/V norm disparity
# scos-lab reports Qwen2.5-7B: 274.0 K mean norm vs 2.6 V mean norm
# This asymmetry directly affects outlier handling
python -c "
from turboquant import rotation, codebook, outlier
# Run calibration on a small model slice
# Verify norms match expected ranges
"
```

**Success criteria**:
- [ ] All turboquant_plus tests pass on CPU
- [ ] K/V norm disparity matches scos-lab findings
- [ ] Codebook generation is deterministic
- [ ] Rotation matrices are orthogonal (numerical check)
- [ ] Outlier detection catches expected anomalies

---

## Experiment 3: SGLang with TurboQuant (AMD Branch)

**Goal**: Port validated TurboQuant into SGLang's modular framework.

**Fork**: `forks/sglang`
**PR**: #21628 — "[AMD] Add TurboQuant KV cache compression for ROCm"

**Why**: Cleanest modular structure. The `turboquant.py` hook pattern makes it easy to add gfx103x override.

**Steps**:
1. Cherry-pick or merge PR #21628 into the local fork
2. Add gfx1030/1031 to the HIP test matrix
3. Set `HSA_OVERRIDE_GFX_VERSION=10.3.0` in the test environment
4. Run the 42 existing unit tests
5. Run end-to-end with OpenCoder 8B

**Success criteria**:
- [ ] 42 unit tests pass on gfx1031
- [ ] `--kv-cache-dtype tq4` works end-to-end
- [ ] RadixAttention still works with TurboQuant KV
- [ ] Memory savings match expectations (~25%)

---

## Experiment 4: vLLM Integration

**Goal**: Get TurboQuant working in vLLM for OpenAI-compatible serving.

**Forks**:
- `forks/vllm` (mainline with PR #38280 patches)
- `forks/vllm-turboquant` (mitkox pre-packaged fork)

**Why last**: vLLM's current TurboQuant path has a **0.36x throughput penalty** (reconstructs bf16 before attention). Only pursue after proving the quantization works.

**Steps**:
1. Start with mitkox/vllm-turboquant (easiest)
2. Verify `--kv-cache-dtype turboquant` flag
3. Run serving benchmark
4. Compare memory usage vs baseline
5. If throughput is acceptable, consider mainline PR integration

**Success criteria**:
- [ ] vLLM starts with TurboQuant KV
- [ ] OpenAI API serves requests
- [ ] Memory reduction ≥ 20%
- [ ] Throughput penalty documented and quantified

**⚠️ Known issue**: 0.36x baseline throughput until fused decode+attention kernel exists. Study dendrite's `PageFormat::TurboQuant4Bit` for the right architecture.

---

## Long-Term Goals (Post-Experiments)

### Speculative Decoding Integration
- Medusa 1.5B draft → EAGLE-3 migration
- Train draft heads with Unsloth on 12 GB (feasible)
- SpecForge for EAGLE draft model training
- ATLAS-style adaptive speculation

### Fused Kernel Development
- Study dendrite's direct quantized-page approach
- Avoid dequantize-then-attend overhead
- Target the vLLM 0.36x bottleneck

---

## Resource Budget

| Resource | Capacity | Constraint |
|----------|----------|------------|
| GPU VRAM | 12 GB | Hard limit — TurboQuant helps fit larger models |
| System RAM | ~60 GB available | Sufficient for CPU-side work |
| CPU | 24 threads (Ryzen 9 3900X) | Compilation is fast |
| Storage | 98 GB models dir | Plenty for experiments |

---

## What to Watch

- TheTom repo: new HIP PRs, gfx103x test results
- SGLang PR #21628: gfx103x being added to CI matrix
- vLLM PR #38280: fused decode+attention kernel progress
- ROCm releases: check override compatibility on upgrades
- zolotukhin/zinc: Zig engine with TurboQuant roadmap (wildcard)

---

See also:
- [Ecosystem Landscape](research/turboquant-gfx1031-landscape.md)
- [Donor Assessment](research/donor-assessment.md)
- [gfx1031 Compatibility](research/gfx1031-rocm-compat.md)
