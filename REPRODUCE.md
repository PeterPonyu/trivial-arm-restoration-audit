# Reproducing the numbers

Every quantity printed in the manuscript is emitted by `paper/figs/make_figs.R`
from the artifacts listed below. None is typed into the prose. The figure code
re-hashes each artifact before reading it, so a modified or missing file stops
the build instead of producing a stale number.

## Bound artifacts

| path | role | bytes | sha256 |
|---|---|---|---|
| `data/e-toy/local_baseline.json` | derived_table | 2023 | `739e2a787c3308d9…` |
| `data/e-withdrawn/paper_measurement_toy_matched_budget.json` | recorded_state | 3916 | `7363376c6b16e0a4…` |
| `data/e-static/static.json` | recorded_state | 422 | `c8f6eea65f526592…` |
| `data/e-naive/naive.json` | recorded_state | 341 | `83a46f404e0f1c18…` |
| `data/e-simple/simple.json` | recorded_state | 346 | `ffa2fb4863926cc6…` |
| `data/e-longer/unet_result_500step.json` | derived_table | 695 | `eab0586ef99b6c43…` |
| `data/e-dit/sota_dit4sr_metrics_today_dit.json` | derived_table | 21405 | `06249f3c7ad2335e…` |
| `data/e-bicubic/sota_dit4sr_metrics_today_bicubic.json` | derived_table | 21394 | `ed3054bcd5107a2a…` |
| `data/e-nearest/sota_dit4sr_metrics_today_nearest.json` | derived_table | 21411 | `b48533beca953d54…` |
| `data/e-bicubic-audit/metrics.json` | derived_table | 21394 | `ed3054bcd5107a2a…` |
| `data/e-dit-earlier/sota_dit4sr_metrics.json` | derived_table | 21442 | `04b1d355a235496b…` |
| `data/e-summary/sota_dit4sr_metrics_today.json` | derived_table | 2159 | `81e21116feaffd9c…` |
| `data/e-strata/sota_dit4sr_metrics_today_reviewer.json` | derived_table | 1648 | `8f92de95e9a3b679…` |
| `data/e-eval/sota_dit4sr_eval.json` | recorded_state | 10354 | `749af50fc0e86631…` |
| `data/e-eval-earlier/sota_dit4sr_eval_20260816T062908Z.json` | recorded_state | 45545 | `06fd3b65c5ae9b41…` |
| `data/e-skip/complement_dit4sr_skip_census.json` | derived_table | 1269 | `1409232fa989e43e…` |
| `data/e-sizes/complement_dit4sr_lq_size_histogram.json` | derived_table | 1447 | `30695b5cd548443a…` |
| `data/e-orphans/complement_dit4sr_13stem_identity.json` | derived_table | 5613 | `5d4bfb206a23f8dc…` |
| `data/e-primary/paper_primary.json` | recorded_state | 503 | `97e416747aa78a65…` |
| `data/e-sota/sota_copy.json` | recorded_state | 562 | `cdfb73588e424076…` |
| `data/e-perceptual-predecl/PREDECLARATION.json` | recorded_state | 6919 | `8a2cafcf89c4969f…` |
| `data/e-perceptual-amend/PREDECLARATION_AMENDMENT_1.json` | recorded_state | 4596 | `4a398c7a4604b789…` |
| `data/e-perceptual/perceptual_summary.json` | derived_table | 7841 | `b7182e5c4a84cece…` |
| `data/e-perceptual-raw/per_crop.jsonl` | derived_table | 63573 | `8fc8c0ea51110475…` |
| `data/e-perceptual-receipt/RECEIPT.json` | recorded_state | 3261 | `eae7ea63a7e76711…` |
| `data/e-perceptual-provenance/PROVENANCE.json` | recorded_state | 4355 | `d8af0402fde94773…` |
| `data/e-init-predecl/PREDECLARATION.json` | recorded_state | 13508 | `2d09abb6bfe534fb…` |
| `data/e-init/init_summary.json` | derived_table | 17059 | `fb54927b93c48d7b…` |
| `data/e-init-analysis/analysis.json` | derived_table | 4457 | `d53ac8e580b1eca2…` |
| `data/e-init-receipt/RECEIPT.json` | recorded_state | 6787 | `0ec809ed0df89017…` |

Some of these files recorded the paths of the machine that produced them. Those path strings and source links were refreshed before deposit; `REDACTION.md` states the rules, lists every file touched with both digests, and describes the check that proves no number changed.

## Not included

This archive leaves out one extra file named in the paper's evidence list. The paper does not take any number from it.

- A private working note. The paper does not use any number from it. Those facts are already in the methods and in the result files included here.

## Checking the archive without building it

```bash
python3 tools/bind_evidence.py paper --check
```

This re-hashes every path above against `paper/evidence/evidence_manifest.json`
and reports the first artifact that has drifted.

## Rebuilding

```bash
bash build.sh
```

The steps are check the files, redraw the figures, then typeset. Each step
must finish before the next one starts.
