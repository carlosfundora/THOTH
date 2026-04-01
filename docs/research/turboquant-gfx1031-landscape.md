# TurboQuant + gfx1031 Ecosystem Landscape

> Research snapshot: March 30–31, 2026
> Hardware target: RX 6700 XT (gfx1031, RDNA2, 12 GB)
> ROCm: 7.2.0 on Ubuntu 24.04

---

## Executive Summary

No turnkey, proven gfx1031 + TurboQuant setup exists today. But the missing pieces are now visible: real AMD HIP kernels exist, vLLM and SGLang both have active ROCm TurboQuant branches, and TheTom just proved the math works on a modern AMD card with HIP. The "Frankenstein path" is shorter and better documented than 3 days ago.

---

## What Changed in the Last 48–72 Hours

The TurboQuant paper is roughly one week old. The landscape has moved fast.

### vLLM PR #38280 — Phases 1 + 2 Merged in Community Forks

- The mainline PR is still draft, but Phases 1 + 2 are now merged in at least two active community forks:
  - **mitkox/vllm-turboquant** (vLLM 0.18.1rc1 + TurboQuant)
  - **Alberto-Codes/turboquant-vllm** — claims "validated on NVIDIA and AMD ROCm (zero code changes)" with 180+ tests and experiment logs
- This is the **first credible public ROCm mention** tied to the PR
- The Triton kernels and `--kv-cache-dtype turboquant` flag are now copy-paste ready from these forks
- **Warning**: The current design still reconstructs bf16 before attention → 0.36x baseline throughput. The real fix requires a fused decode+attention kernel.

### SGLang PR #21617 → New AMD-Specific Follow-Up

- Original PR #21617 is still WIP
- **PR #21628 landed**: "[AMD] Add TurboQuant KV cache compression (--kv-cache-dtype tq2/tq3/tq4) for ROCm"
  - Includes AMD HIP test workflows
  - Targets gfx11xx/gfx12xx families
  - gfx103x is **not yet in the matrix**, but the modular `turboquant.py` hook makes it the cleanest place to add the override
  - 42 passing unit tests reported

### TheTom Ecosystem — Biggest New AMD Signal

- **@no_stp_on_snek** (the maintainer) posted live benchmarks on an **RX 9070 XT** (RDNA4, gfx1201) with HIP SDK 7.1:
  - Qwen2.5-7B Q4_K_M + turbo4 → **no speed penalty**, actually +~2 t/s decode vs baseline
  - **25% less KV memory**
  - "gfx1201 detected natively — no HSA_OVERRIDE needed"
- Same repo (`TheTom/llama-cpp-turboquant`, branch `feature/turboquant-kv-cache`) still documents `HSA_OVERRIDE_GFX_VERSION=10.3.0` for RDNA2 (explicitly lists gfx1030/1031/1035)
- New HIP PR (#31) merged
- Issue #21096 opened: HIP aperture violation on turbo3 with RX 9070 XT → RDNA4 showing edge-case fragility, RDNA2 is still the safer starting point

### Brand-New or Low-Visibility Forks

| Fork | What It Is | Why It Matters |
|------|-----------|----------------|
| **peva3/turboquant-h2o-streamingllm** | TurboQuant 4-bit + H2O attention skipping | Full AMD/HIP kernels (`turboquant_hip.h/cpp`) |
| **unixsysdev/llama-turboquant** | Adds TQ3_0 type | HIP build instructions include gfx1030/1031 targets |
| **zolotukhin/zinc** | Brand-new Zig inference engine for consumer AMD GPUs | TurboQuant KV + paged cache in roadmap |
| **mitkox/vllm-turboquant** | Pre-packaged vLLM + TurboQuant | Easiest drop-in for serving tests |
| **Alberto-Codes/turboquant-vllm** | vLLM fork with 180+ tests | Claims ROCm validation (zero code changes) |

---

## ROCm / gfx1031 Compatibility Status

### The Override Hack

`HSA_OVERRIDE_GFX_VERSION=10.3.0` remains the universal escape hatch:
- Confirmed working in: Ollama, llama.cpp, Fedora HC, rocm_sdk_builder threads
- No new official ROCm support for gfx1031 (still "not listed")
- Fedora 45/EPEL and lamikr/rocm_sdk_builder ship patched stacks that treat gfx1031 as gfx1030

### AMD's Current Focus

- ROCm on Radeon currently highlights **Radeon 9000 and select 7000 series** for expanded platform support
- RX 6700 XT class hardware is **not centered** in official messaging
- Community and distro layers are more promising than official turnkey binaries

### Battle-Tested Hacks Are More Robust Now

- Multiple independent confirmations of override working across ROCm discussions, PyTorch forums, and llama.cpp build notes
- The pattern is operational, not a one-off hallucination
- But it is still **unofficial and brittle** — library-target mismatches can break at any ROCm version bump

### TheTom AMD Run Gotchas

- Windows + HIP has "9 gotchas" (mostly DLL/rocBLAS path issues)
- **Linux is cleaner** — our target environment

---

## Ecosystem Map

```
┌─────────────────────────────────────────────────────────────┐
│                    TurboQuant Paper                         │
│                  (Google, ~1 week old)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   ┌──────────┐   ┌──────────┐   ┌──────────────┐
   │ llama.cpp│   │  vLLM    │   │   SGLang     │
   │ (HIP)   │   │ PR#38280 │   │ PR#21617/28  │
   └────┬─────┘   └────┬─────┘   └──────┬───────┘
        │               │               │
   TheTom fork    mitkox fork     AMD branch
   + HSA_OVERRIDE + Alberto fork  + gfx11/12 CI
   + gfx1031 docs + 180+ tests   + turboquant.py
        │               │               │
        ▼               ▼               ▼
   ┌──────────────────────────────────────────┐
   │     Algorithm Donors                      │
   │  turboquant_plus (Apache-2.0)            │
   │  scos-lab/turboquant (calibration)       │
   │  0xSero/turboquant (GPL-3.0, read-only)  │
   │  dendrite (PageFormat, direct quant)     │
   └──────────────────────────────────────────┘
        │
        ▼
   ┌──────────────────────────────────────────┐
   │     ROCm / gfx1031 Infrastructure        │
   │  rocm_sdk_builder (patch farm)           │
   │  TheRock (gfx103X-all plumbing)          │
   │  aotriton (blocker — no gfx103x)         │
   │  Fedora HC/ROCm SIG (gfx1031 matrix)    │
   └──────────────────────────────────────────┘
```

---

## Verdict

The gap between "plausible" and "I have it running" shrank noticeably in 72 hours. The recommended attack order: prove TurboQuant on gfx1031 in HIP llama.cpp first, harvest algorithm pieces from turboquant_plus and scos-lab, then port the format into SGLang or vLLM once you know the quantization itself behaves on the hardware.

See also:
- [Donor Assessment](donor-assessment.md)
- [gfx1031 ROCm Compatibility](gfx1031-rocm-compat.md)
- [Attack Plan](../attack-plan.md)
