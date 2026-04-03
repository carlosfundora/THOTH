# Bonsai 1.7B Local EAGLE3 + `tq4` Docker Blocker

Date: `2026-04-03`  
Engine: `sglang`  
Environment: `thoth` Docker container  
Path: `Bonsai-1.7B GGUF + local EAGLE3 draft + --kv-cache-dtype tq4 + Triton + radix`

## Result

Blocked on the first real request.

| Check | Result | Evidence |
|------|--------|----------|
| server boot | ✅ | [`20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log) |
| `/model_info` | ✅ | same log |
| target extend | ✅ | same log |
| draft extend begins | ✅ | same log |
| `/generate` | ❌ | same log |

## Failure Boundary

The active failure is a ROCm queue abort with:

- `HSA_STATUS_ERROR_EXCEPTION`
- visible kernel: `indexSelectSmallIndex ... Half`

In the best current repro, the sequence is:

1. server becomes ready
2. `/model_info` returns `200`
3. target extend completes
4. draft extend starts
5. the queue aborts before the request returns

The trace still points back to the TurboQuant packed-KV compression / write path:

- [`memory_pool.py`](/home/local/Projects/THOTH/forks/sglang/python/sglang/srt/mem_cache/memory_pool.py)
- `_compress_heads()`
- `set_kv_buffer()`

## Peak Sampled Resources

- container memory before abort: `10.19 GiB`
- GPU junction before abort: `46 C`
- VRAM allocation before abort: `31%`

## Artifacts

- [`20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed.log)
- [`20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl`](/home/local/Projects/THOTH/logs/20260403T045050_bonsai17_eagle3_tq4_ctx1k_rowembed_resources.jsonl)
