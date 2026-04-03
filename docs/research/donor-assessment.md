# Donor Assessment — TurboQuant Fork Shopping List

> What to steal from each fork, what to avoid, and license constraints.
> Last updated: 2026-03-31

---

## Tier 1 — Highest-Value Immediate Donors

### TheTom/llama-cpp-turboquant ⭐ START HERE

- **Branch**: `feature/turboquant-kv-cache`
- **Local fork**: `forks/llama-turboquant`
- **License**: MIT (llama.cpp upstream)
- **Value**: Shortest path to "TurboQuant runs on gfx1031"
- **What to steal**:
  - HIP build configuration with `HSA_OVERRIDE_GFX_VERSION=10.3.0`
  - Explicit gfx1030/1031/1035 documentation in `docs/build.md`
  - TurboQuant KV cache dtype integration (`--kv-cache-dtype turbo4`)
  - HIP kernel paths (PR #31 merged)
- **Why it matters**: The RX 9070 XT success yesterday proves the math works on AMD HIP. Same code path that gfx1031 override piggybacks on.
- **Gotchas**: RDNA4 showing edge-case fragility (issue #21096). RDNA2 is safer.

### TheTom/turboquant_plus ⭐ ALGORITHM TRUTH SOURCE

- **Local fork**: `forks/turboquant_plus`
- **License**: Apache-2.0 ✅ (safe to assimilate directly)
- **Value**: Best algorithm donor — cleanest decomposition of the paper
- **What to steal**:
  - `rotation.py` — rotation matrices
  - `codebook.py` — codebook generation
  - `polar_quant.py` — polar quantization
  - `qjl.py` — QJL (Quantized Johnson-Lindenstrauss) projections
  - `turboquant.py` — core TurboQuant logic
  - `kv_cache.py` — KV cache integration
  - `outlier.py` — outlier handling
- **Why it matters**: Reusable components, clean separation, permissive license.

### peva3/turboquant-h2o-streamingllm

- **Local fork**: `forks/turboquant-h2o-streamingllm`
- **License**: Check upstream
- **Value**: Full TurboQuant 4-bit + H2O attention skipping with explicit AMD/HIP kernels
- **What to steal**:
  - `turboquant_hip.h` / `turboquant_hip.cpp` — HIP kernel implementations
  - H2O eviction logic on top of TurboQuant
- **Why it matters**: If you want attention skipping + quantization combined.

---

## Tier 2 — Serving Engine Donors

### vLLM PR #38280 (vllm-project/vllm)

- **Local fork**: `forks/vllm`
- **Status**: Draft PR, but Phases 1+2 merged in community forks
- **Value**: Layout/backend donor (not first production port)
- **What to steal**:
  - `--kv-cache-dtype turboquant` plumbing
  - `TurboQuantBackend` class
  - 95-byte per-token-per-head KV slot layout
  - Fused Triton encode/decode path
  - Benchmark/test harness
- **⚠️ Big Warning**: Current design reconstructs bf16 before attention → **0.36x baseline throughput**. The fix is a fused decode+attention kernel that doesn't exist yet.
- **Verdict**: Steal layout + interfaces first. Don't ship the slow path.

### mitkox/vllm-turboquant

- **Local fork**: `forks/vllm-turboquant`
- **Value**: Pre-packaged vLLM 0.18.1rc1 + TurboQuant
- **What to steal**: Easiest drop-in for serving tests if llama.cpp works first.

### Alberto-Codes/turboquant-vllm

- **Not forked locally** (consider adding)
- **Value**: Claims "validated on NVIDIA and AMD ROCm (zero code changes)" with 180+ tests
- **What to steal**: Test harness, experiment logs, ROCm validation methodology

### SGLang PR #21617 + PR #21628

- **Local fork**: `forks/sglang`
- **Value**: Cleanest modular structure for ROCm port
- **What to steal**:
  - Centralized `turboquant.py` hook pattern
  - FlashInfer and Triton backend hooks
  - Model-runner dtype integration
  - Test suite (42 passing unit tests)
  - **PR #21628 (new)**: AMD HIP test workflows, gfx11xx/gfx12xx targets
- **Note**: gfx103x not yet in the CI matrix, but `turboquant.py` hook is the cleanest place to add the override.

---

## Tier 3 — Reference / Calibration Sources

### 0xSero/turboquant

- **Local fork**: `forks/turboquant`
- **License**: ⚠️ GPL-3.0 — **read-only reference, do not copy code**
- **Value**: Standalone reference implementation with Triton kernels + vLLM integration
- **Tested on**: vLLM 0.18.0 / PyTorch 2.10 / CUDA 12.8 (RTX 3090, 5090)
- **Use as**: Architectural map and code-reading target only

### scos-lab/turboquant

- **Not forked locally** (consider adding for calibration data)
- **Value**: Calibration and correctness lab
- **What to steal**: Engineering observations the paper glosses over:
  - **K/V norm disparity**: Qwen2.5-7B shows 274.0 K mean norm vs 2.6 V mean norm
  - This directly influences outlier handling and calibration strategy
- **Verdict**: Run their test suite on CPU as Experiment 2 validation.

### BioInfo/dendrite

- **Local fork**: `forks/dendrite`
- **Value**: Most valuable donor for **runtime architecture**, not paper math
- **What to steal**:
  - `PageFormat::TurboQuant4Bit` — operates directly on quantized indices
  - Avoids dequantize-then-attend overhead (the stupidest performance trap in first-gen ports)
  - 3.88x memory reduction claimed
- **Verdict**: Study this architecture to avoid the vLLM 0.36x throughput trap.

---

## Tier 4 — ROCm / gfx1031 Infrastructure

### lamikr/rocm_sdk_builder

- **Location**: `/home/local/Projects/build/rocm_sdk_builder` (not in THOTH/forks)
- **Value**: Most useful patch farm for consumer AMD GPUs
- **What to steal**:
  - Tested on RX 6700 / 6700 XT (gfx1031) ✅
  - Ubuntu 24.04 + Arch Linux support
  - vLLM build/test flows included
  - Formal patch application system under `patches/rocm-x.y.z/...`
  - Per-project patch stack patterns
- **Verdict**: Mine for patch sets before inventing your own.

### ROCm/TheRock

- **Local fork**: `build-resources/TheRock`
- **Value**: Not a finished solution, but important for PyTorch-side build logic
- **What to steal**:
  - Target family plumbing: `gfx103X-all`, `gfx103X-dgpu`
  - Grouped AMDGPU target option patterns
  - Family-selection plumbing for gfx1031-aware builds

### ROCm/aotriton

- **Local fork**: `build-resources/aotriton`
- **Value**: ⚠️ **Blocker map, not a donor**
- **Status**: Recent releases target gfx950, gfx1201, gfx1101, gfx1151, gfx1150, gfx1200 — **not gfx103x**
- **Impact**: AOTriton is what PyTorch uses for SDPA/FlashAttention paths → gfx1031 PyTorch route remains a patching project

---

## Additional Community Forks (Watch List)

| Fork | Status | Notes |
|------|--------|-------|
| unixsysdev/llama-turboquant | Active | Adds TQ3_0 type; HIP build includes gfx1030/1031 |
| zolotukhin/zinc | Brand-new | Zig inference engine for consumer AMD; TurboQuant KV in roadmap |

---

## License Summary

| Fork | License | Can Copy? |
|------|---------|-----------|
| turboquant_plus | Apache-2.0 | ✅ Yes, freely |
| llama-cpp-turboquant | MIT | ✅ Yes, freely |
| dendrite | Check | ⚠️ Verify |
| scos-lab/turboquant | Check | ⚠️ Verify |
| 0xSero/turboquant | GPL-3.0 | ❌ Read-only reference |
| vLLM (upstream) | Apache-2.0 | ✅ Yes |
| SGLang (upstream) | Apache-2.0 | ✅ Yes |
