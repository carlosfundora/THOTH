# THOTH Attack Plan

> Goal: TurboQuant KV cache + speculative decoding on RX 6700 XT (gfx1031)
> Frozen 8B target (OpenCoder) + adaptive 1.5B draft (Medusa → EAGLE-3)
> Last updated: 2026-04-03

Quickstart / location map:
- [`docs/quickstart.md`](quickstart.md)

---

## Principle

Prove TurboQuant on gfx1031 in HIP llama.cpp first, harvest algorithm pieces from turboquant_plus and scos-lab, then port the format into SGLang or vLLM once quantization behaves on the hardware. That is the least stupid order of operations.

---

## Experiment 1: HIP llama.cpp First ✅ DONE

**Goal**: Prove TurboQuant runs at all on gfx1031. **PROVEN.**

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
- [x] Binary compiles with HIP/gfx1030 (TQ3_0 is native, no cmake flag needed)
- [x] `rocm-smi` shows GPU memory allocated
- [x] `--cache-type-v tq3_0 --flash-attn on` — coherent output (V-only is the winning config)
- [x] Output is coherent — verified on OpenCoder 1.5B and 8B
- [x] KV memory usage reduced 39% (840→511 MiB on 1.5B, 1024→624 MiB on 8B)
- [x] **Bonus**: Q1_0 1-bit ternary port — all 3 Bonsai models (1.7B/4B/8B) working

**Key finding**: V-only TQ3_0 is the winner config. K-only causes garbled output.
See [smoke-tests-run001](engines/llama-turboquant/smoke-tests-run001.md) and [q1_0-port-results](engines/prismml-llama/q1_0-port-results.md).

**GPU Bonsai Q1_0 Results** (2026-04-01, PrismML HIP build):
- Bonsai-4B: **857 t/s prompt, 121 t/s generation** (540 MiB, fits 22× in VRAM)
- Bonsai-8B: **454 t/s prompt, 92 t/s generation** (1.07 GiB)
- Bonsai-1.7B: **2097 t/s prompt, 76 t/s generation** (231 MiB)
- See [gpu-benchmark-results](engines/prismml-llama/gpu-benchmark-results.md)

**LFM2 + TQ3_0 Test**: ❌ Garbled — TQ3_0 KV cache corrupts LFM2's hybrid RNN state. Only works with standard transformer attention (OpenCoder).

**Fork Merge Completed**: TQ3_0 KV cache has been successfully ported into the PrismML fork (`feature/tq3_0-kv-cache`). Combined `Q1_0` weight + `TQ3_0` K-cache + `F16` V-cache combo runs correctly on GPU, yielding bandwidth and VRAM reductions at the cost of `flash_attn` disabling for K-cache.

**Failure modes to watch**:
- HIP aperture violation → check HSA_OVERRIDE is set
- `invalid device function` → ROCm version mismatch
- Garbage output → quantization drift, go to Experiment 2

---

## Experiment 2: Algorithm Validation on CPU ✅ DONE

**Goal**: Separate algorithm validation from runtime validation. Verify rotation, codebook, outlier, and QJL behavior independently. **ALL PASSED.**

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
- [x] All turboquant_plus tests pass on CPU — **557/557 passed in 37.86s**
- [x] K/V norm disparity — covered by distortion tests at d={128,256,512}
- [x] Codebook generation is deterministic
- [x] Rotation matrices are orthogonal (numerical check)
- [x] Outlier detection catches expected anomalies (2.5-bit and 3.5-bit configs)

See [validation-results](engines/turboquant-plus/validation-results.md).

---

## Experiment 3: SGLang with TurboQuant / EAGLE / 1-bit ✅ VALIDATED

**Goal**: Port validated TurboQuant into SGLang's modular framework, then use SGLang as the real EAGLE target.

**Fork**: `forks/sglang`
**TurboQuant donor PR**: `#21628` — "[AMD] Add TurboQuant KV cache compression for ROCm"

**Why**: SGLang is now the correct runtime for true EAGLE. llama.cpp proved the HIP and TurboQuant path, but it is not the final home for EAGLE.

**What is already done**:
1. Cherry-pick PR `#21628` into the local fork
2. Patch `sgl-kernel/setup_rocm.py` so the ROCm extension builds on `gfx1030` compatibility
3. Add Prism GGUF compatibility shims for Bonsai `Q1_0` / `Q1_0_G128`
4. Add HIP GGUF fallback behavior so ROCm can load quantized GGUF models without CUDA-only kernels
5. Relax ROCm GGUF gating in model config so SGLang no longer rejects the format up front
6. Stand up a Docker-first `.venv-sglang` inside the THOTH container for all SGLang runtime work

**Validated runtime track**:
1. Bonsai 1.7B GGUF on SGLang now serves end-to-end in both:
   - `local EAGLE3 + Triton + radix`
   - `local EAGLE3 + tq4 + Triton + radix`
2. OpenCoder 1.5B on SGLang serves end-to-end with:
   - `--speculative-algorithm EAGLE3`
   - `--kv-cache-dtype tq4`
   - Triton + radix on ROCm gfx1030 compatibility
3. Training follow-through remains after runtime proof, because production OpenCoder still benefits from a real EAGLE draft artifact rather than relying only on bring-up checkpoints

**Resolved blockers**:
- The first OpenCoder EAGLE3 load failure was a bad local weights checkout, not a ROCm port failure:
  - `model-00002-of-00004.safetensors` was corrupt and had to be re-fetched from Git LFS
- Bonsai GGUF coherence required fixing GGUF type-name handling so unquantized norm weights are loaded correctly
- Bonsai draft extend required preserving the draft projection dtype in `llama_eagle3.py`
- The validated Docker runtime state is now:
  - `OpenCoder-1.5B + local EAGLE3 + tq4 + Triton + radix` works and returns `200 OK`
  - `Bonsai-1.7B + local EAGLE3 + Triton + radix` works and returns `200 OK`
  - `Bonsai-1.7B + local EAGLE3 + tq4 + Triton + radix` works and returns `200 OK`

**Success criteria**:
- [x] Bonsai `Q1_0` serves end-to-end in SGLang on ROCm
- [x] OpenCoder local `EAGLE3` + `tq4` works end-to-end in SGLang
- [x] OpenCoder runtime reaches a true EAGLE-compatible serve path
- [ ] Training path is ready to produce a real OpenCoder EAGLE draft artifact once runtime proof is stable

**Next goal**:
- run `EAGLE3` semantics on both the draft model and the generation model simultaneously without regressing the validated Docker paths above

**Next phase additions**:
- harden `forks/llama-turboquant` with loader and server guardrail regressions before broader upstreaming
- keep ROCm host-buffer defaults and KV-cache guardrails explicit on the llama side
- upstream from `llama-turboquant` in small review branches:
  - PrismML `Q1_0` / `Q1_0_G128`
  - null-context guard
  - ROCm hardening tests and docs
- do **not** upstream `forks/llama.cpp` yet: the only local standalone ROCm guard commit is currently an accidental symlink placeholder and must be rebuilt as a real source patch first
- cleanup-first P-EAGLE work is now the active SGLang/SpecForge phase:
  - `forks/sglang` validated branch stays on `sglang-turboquant-1-bit_gfx1030`, with post-validation experiments split off to `local/dual-eagle3-experiments-rocm`
  - `forks/SpecForge` reusable runtime/training changes live on `thoth/eagle3-runtime-clean`, while local-only config artifacts remain quarantined on `local/eagle3-configs-and-training`
  - the first P-EAGLE foundation is in flight for `OpenCoder-1.5B`:
    - SpecForge draft config fields: `parallel_drafting`, `mask_token_id`, `k_train`, `cod_retention`
    - SpecForge draft head parameter: `mask_hidden`
    - SGLang runtime enum/validation support: `P_EAGLE`
- Bonsai-1.7B is now the preferred first THOTH P-EAGLE training target because it is the faster local runtime canary
- Use `prism-ml/Bonsai-1.7B-unpacked` for HF/Transformers training, while keeping the local GGUF as the runtime artifact
- Canonical live SGLang runtime target is `forks/sglang/.venv-sglang`, bridged to the shared ROCm base venv
- The shared ROCm base venv should continue to provide PyTorch/ROCm dependencies only; it should not be the direct SGLang install target
- The stale user-local editable SGLang install under `~/.local` should be retired from normal use
- Current cutover reality is:
  - `sglang` imports from the THOTH fork
  - `sgl_kernel` still imports from the shared ROCm base wheel
  - `triton` still imports from the user-site ROCm install
  - local THOTH `sgl-kernel` sources and dirty `build-resources/triton` / `build-resources/pytorch` trees are not yet proven to be part of the live stack
- Current provenance audit:
  - [`reports/sglang/live-install-cutover-2026-04-03.md`](../reports/sglang/live-install-cutover-2026-04-03.md)
- Use the `bonsai17_smoke` launcher profile first when validating the training path end-to-end on gfx1030
  - the Triton large-vocab loss blocker is now fixed by chunked block-size selection in `specforge/core/loss.py`
  - the parallel warm-start upgrade path must explicitly zero any missing `mask_hidden` tensor when loading older Bonsai EAGLE-3 checkpoints
  - the active parallel-debug gate is now: first non-finite tensor boundary in `OnlineEagle3Model`, not generic loss failure
  - the validated low-VRAM smoke path on this box is:
    - `sdpa` attention backend
    - `ttt_length=5`
    - `k_train=5`
    - `train_mask_hidden_only=true`
    - writable output path under `THOTH/artifacts/models/local/`
  - every host-side training launch should retire competing THOTH/model-serving jobs before it starts
  - first smoke artifact is complete and reloads successfully:
    - `/home/local/Projects/THOTH/artifacts/models/local/Bonsai-1.7B-P-EAGLE-local-smoke/epoch_0_step_2`
  - current remaining gap is not framework bring-up; it is widening from the low-VRAM smoke mode to a broader full-parameter run without exceeding the ROCm memory budget
  - current install/cutover work must normalize all active launchers to the absolute `.venv-sglang` python path rather than relying on `PATH` or the stale `~/.local/bin/sglang`

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
