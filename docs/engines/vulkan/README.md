# Vulkan Backend — Engine Notes

**Status:** Source present, not compiled
**Source:** `THOTH/forks/llama-turboquant/ggml/src/ggml-vulkan/` (152+ compute shaders)

---

## Plan

1. Add `-DGGML_VULKAN=ON` to `docker/Dockerfile` cmake flags
2. Rebuild Docker image
3. Compare HIP vs Vulkan inference on same models
4. Document performance delta

## Build Flag
```cmake
cmake -S .. -B . \
  -DGGML_HIP=ON \
  -DGGML_VULKAN=ON \    # ADD THIS
  -DGPU_TARGETS=gfx1030 \
  -DCMAKE_BUILD_TYPE=Release
```

HIP and Vulkan can coexist in the same binary as separate shared libraries.

## Why Vulkan
- Portability fallback when HIP has issues
- May perform differently on RDNA2 (gfx1031) for certain operations
- Useful for testing on non-ROCm systems
