# llama-turboquant ROCm Hardening Report

**Date:** 2026-04-03  
**Repo:** `/home/local/Projects/THOTH/forks/llama-turboquant`  
**Commit:** `8ec5312018947c46e30c43a17eb53e90ab46a89b`

## Scope

This hardening pass added the smallest useful protections for failure classes
that later surfaced during the SGLang ROCm work:

- GGUF float tensor type regression coverage
- explicit parser coverage for `tq3_0` KV-cache flags and `--no-host`
- server-side guardrail coverage for invalid quantized V-cache + Flash
  Attention combinations
- docs clarifying ROCm host-buffer policy and supported cache-type flags

## Files

- [`tests/test-rocm-hardening.cpp`](/home/local/Projects/THOTH/forks/llama-turboquant/tests/test-rocm-hardening.cpp)
- [`tests/test-arg-parser.cpp`](/home/local/Projects/THOTH/forks/llama-turboquant/tests/test-arg-parser.cpp)
- [`tests/CMakeLists.txt`](/home/local/Projects/THOTH/forks/llama-turboquant/tests/CMakeLists.txt)
- [`tools/server/tests/unit/test_speculative.py`](/home/local/Projects/THOTH/forks/llama-turboquant/tools/server/tests/unit/test_speculative.py)
- [`tools/server/README.md`](/home/local/Projects/THOTH/forks/llama-turboquant/tools/server/README.md)

## Validation

Built in:

- `/home/local/Projects/THOTH/forks/llama-turboquant/build-hardening`

Validated commands:

```bash
cmake --build /home/local/Projects/THOTH/forks/llama-turboquant/build-hardening \
  --target test-arg-parser test-rocm-hardening llama-server -j4

cd /home/local/Projects/THOTH/forks/llama-turboquant/build-hardening
ctest --output-on-failure -R 'test-arg-parser|test-rocm-hardening'

cd /home/local/Projects/THOTH/forks/llama-turboquant/tools/server/tests
LLAMA_SERVER_BIN_PATH=/home/local/Projects/THOTH/forks/llama-turboquant/build-hardening/bin/llama-server \
  ../../../.venv-tests/bin/pytest -q unit/test_speculative.py -k 'quantized_v_cache_requires_flash_attention'
```

Observed results:

- `test-arg-parser`: pass
- `test-rocm-hardening`: pass
- `test_quantized_v_cache_requires_flash_attention`: pass

## Upstream Branches

Published review branches on `carlosfundora/llama-turboquant`:

- `review/prismml-q1-support`
- `review/null-context-guard`
- `review/rocm-hardening`

## Known Blocker Outside This Repo

The analogous standalone `forks/llama.cpp` upstream prep is **not** ready from
this pass. The local commit labeled as the ROCm null-context guard was audited
and found to be an accidental symlink placeholder, not a reviewable source
patch.
