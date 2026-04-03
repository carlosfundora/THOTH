# P-EAGLE Canonical Sources

Date: `2026-04-03`

## Added / Verified in `THOTH/forks`

### `forks/EAGLE`

- local path: [`forks/EAGLE`](/home/local/Projects/THOTH/forks/EAGLE)
- fork remote: `https://github.com/carlosfundora/EAGLE.git`
- upstream remote: `https://github.com/SafeAILab/EAGLE.git`
- role:
  - canonical EAGLE-1 / EAGLE-2 / EAGLE-3 donor
  - reference drafter architecture
  - reference hidden-state fusion and training flow

### `forks/speculators`

- local path: [`forks/speculators`](/home/local/Projects/THOTH/forks/speculators)
- source remote: `https://github.com/vllm-project/speculators.git`
- checked-out commit: `f60edbb`
- role:
  - canonical P-EAGLE training/model-definition donor
  - `mask_hidden`
  - mask token embedding logic
  - COD / sequence-partitioning training path
  - parallel input builder reference

### `forks/vllm`

- local path: [`forks/vllm`](/home/local/Projects/THOTH/forks/vllm)
- fork remote: `https://github.com/carlosfundora/vllm.git`
- upstream remote: `https://github.com/vllm-project/vllm.git`
- role:
  - production inference donor
  - unified parallel drafting / P-EAGLE serving reference
  - `vllm/spec_decode/` implementation surface

### `forks/SpecForge`

- local path: [`forks/SpecForge`](/home/local/Projects/THOTH/forks/SpecForge)
- fork remote: `https://github.com/carlosfundora/SpecForge.git`
- upstream remote expected by roadmap: `https://github.com/sgl-project/SpecForge`
- role:
  - THOTH-local training integration base
  - OpenCoder-1.5B first implementation surface

## Immediate Use

The donor order for THOTH P-EAGLE work is now:

1. `forks/speculators` for P-EAGLE model/training definitions
2. `forks/vllm` for serving/runtime integration details
3. `forks/EAGLE` for baseline EAGLE architecture/training comparisons
4. `forks/SpecForge` as the local implementation base
