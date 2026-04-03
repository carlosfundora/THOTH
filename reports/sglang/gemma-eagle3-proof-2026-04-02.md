# Gemma EAGLE3 Proof — 2026-04-02

Source: `/home/local/Projects/THOTH/forks/SpecForge`

## Status

Blocked on local assets.

## What Exists

- SpecForge training config exists:
  [`gemma3-1b-eagle3.json`](/home/local/Projects/THOTH/forks/SpecForge/configs/gemma3-1b-eagle3.json)
- SpecForge training example exists:
  [`run_gemma3_1b_eagle3_online.sh`](/home/local/Projects/THOTH/forks/SpecForge/examples/run_gemma3_1b_eagle3_online.sh)

## What Is Missing

- no local Gemma target checkpoint under the active container model registry
- no local trained Gemma EAGLE3 draft artifact

## Implication

True EAGLE proof in THOTH is now blocked by model assets and training output, not
by the old generic SGLang boot problem.
