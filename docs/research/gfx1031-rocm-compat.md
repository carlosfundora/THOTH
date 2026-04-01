# gfx1031 ROCm Compatibility Intelligence

> RX 6700 XT — RDNA2, gfx1031, 12 GB VRAM
> ROCm 7.2.0 on Ubuntu 24.04
> Last updated: 2026-03-31

---

## The Override Hack

### HSA_OVERRIDE_GFX_VERSION=10.3.0

This is the universal escape hatch for running gfx1031 hardware on ROCm stacks that only officially support gfx1030.

```bash
export HSA_OVERRIDE_GFX_VERSION=10.3.0
```

**Confirmed working in**:
- Ollama
- llama.cpp (HIP backend)
- TheTom/llama-cpp-turboquant (explicitly documents gfx1030/1031/1035)
- Fedora HC / ROCm SIG builds
- lamikr/rocm_sdk_builder
- PyTorch (with LD_LIBRARY_PATH fixes)
- Various community ROCm discussion threads

**Why it works**: gfx1031 and gfx1030 are both RDNA2. The ISA is compatible; the only difference is minor hardware configuration. The override tells the ROCm runtime to treat the device as gfx1030.

**Why it's still brittle**: Library-target mismatches can break at any ROCm version bump. The problem is not one single switch — it's a moving stack of mismatches.

---

## Known Breakage Patterns

### TensileLibrary_lazy_gfx1031.dat Missing

- **Symptom**: `TensileLibrary_lazy_gfx1031.dat: No such file or directory`
- **Cause**: rocBLAS ships pre-compiled Tensile kernels only for officially supported targets. gfx1031 is not in the matrix.
- **Fix**: Use `HSA_OVERRIDE_GFX_VERSION=10.3.0` so it loads `gfx1030` kernels instead, OR rebuild rocBLAS/Tensile with gfx1031 target.
- **Source**: ROCm GitHub issue from RX 6700 XT user

### ROCm Version Regressions

- **ROCm 5.7**: `HSA_OVERRIDE_GFX_VERSION=10.3.0` worked
- **ROCm 6.2**: Same override **failed** with `invalid device function`
- **ROCm 7.2**: Current reports suggest override works again, but test thoroughly
- **Lesson**: Each ROCm major version can re-break the override. Always test after upgrades.

### MIOpen Memory Access Fault

- **Symptom**: Memory access fault on gfx1031 with HSA_OVERRIDE
- **Source**: MIOpen GitHub issue
- **Status**: Workarounds exist; may require specific MIOpen version pinning

### PyTorch Segfault

- **Symptom**: Segmentation fault on ROCm import
- **Fix**: Set `HSA_OVERRIDE_GFX_VERSION=10.3.0` AND fix `LD_LIBRARY_PATH` to point to correct ROCm libs
- **Source**: PyTorch Forums thread from 6700 XT user

---

## Distro / Community Support

### Fedora HC / ROCm SIG

- **Status**: gfx1031 explicitly listed under supported hardware for **Fedora 45 / EPEL 10.3**
- **Caveat**: Some packages still have "limited GPU support" — specifically:
  - Composable Kernel
  - hipBLASLt
- **Value**: Distro-packager layer has a more pragmatic gfx1031 story than AMD's glossy docs

### lamikr/rocm_sdk_builder

- **Location**: `/home/local/Projects/build/rocm_sdk_builder`
- **Status**: **Tested on RX 6700 / RX 6700 XT (gfx1031)** ✅
- **Supports**: Ubuntu 24.04, Arch Linux
- **Features**:
  - Formal patch application system (`patches/rocm-x.y.z/...`)
  - Per-project patch stacks
  - vLLM build/test flows
  - Consumer GPU targeting
- **Verdict**: Best patch farm for gfx1031. Mine it before inventing your own patches.

### Level1Techs Community

- A user explicitly reported **extending ROCm library support to Navi22 / gfx1031**:
  - Extended: rocThrust, rocPRIM
  - Custom versions worked and passed tests
  - Remaining issue: getting hipcc to use modified headers/libs
- **Value**: Confirms code exists in the wild, even if not nicely packaged

### Phoronix Forums

- Multiple posts argue AMD's published support pages **understate** what actually works
- Specifically claim gfx1031 can use gfx1030 as override because both are RDNA2
- **Verdict**: Treat as leads, not gospel

---

## AMD's Official Position

- **Hardware spec**: RX 6700 XT is officially gfx1031 with 12 GB VRAM
- **ROCm on Radeon**: Currently highlights **Radeon 9000 and select 7000 series** for expanded platform support
- **RX 6700 XT**: Not centered in official messaging anymore
- **gfx1031**: Not in official ROCm support matrix
- **Reality**: Community and distro layers are currently more promising than official turnkey binaries

---

## ROCm / TheRock Build System

The new ROCm build system (TheRock) already understands target families:
- `gfx103X-all`
- `gfx103X-dgpu`
- Grouped AMDGPU target options

This means family-selection plumbing for gfx1031-aware builds is conceptually there, even if polished binaries lag.

## AOTriton — The Blocker

AOTriton (AMD's Triton fork for FlashAttention / SDPA) recent releases target:
- gfx950, gfx1201, gfx1101, gfx1151, gfx1150, gfx1200
- **No gfx103x coverage**

Since PyTorch uses AOTriton for some attention paths, the PyTorch-on-gfx1031 route remains a **patching project**, not a turnkey install.

---

## Environment Variables Cheat Sheet

```bash
# Required for gfx1031
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# GPU selection
export HIP_VISIBLE_DEVICES=0

# Build targets
export GPU_TARGETS=gfx1030   # gfx1031 piggybacks

# Sometimes needed
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH

# For cmake builds
HIPCXX="$(hipconfig -l)/clang"
HIP_PATH="$(hipconfig -R)"
```

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| HSA_OVERRIDE breaks on ROCm upgrade | High | Pin ROCm version, test before upgrading |
| TensileLibrary missing | Medium | Override forces gfx1030 kernels; rebuild if needed |
| MIOpen memory faults | Medium | Pin MIOpen version, disable MIOpen paths if possible |
| AOTriton no gfx103x | High | Avoid PyTorch FlashAttention; use llama.cpp HIP path |
| RDNA4 fragility spilling to RDNA2 | Low | RDNA2 is the safer, more tested platform currently |

---

See also:
- [Ecosystem Landscape](turboquant-gfx1031-landscape.md)
- [Donor Assessment](donor-assessment.md)
- [Attack Plan](../attack-plan.md)
