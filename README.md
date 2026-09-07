# Print the trivial arm: three scales at which a do-nothing baseline decided what an image restoration comparison could conclude

Toy training records, per-crop fidelity tables for a released restoration model and two interpolations, inference manifests, a memory-ceiling skip census, figure code and manuscript source for a study showing that at three scales of one restoration project the untouched input or the cheapest interpolation determined what the comparison could conclude.

Archived at [10.5281/zenodo.22647026](https://doi.org/10.5281/zenodo.22647026).

Repository: https://github.com/PeterPonyu/trivial-arm-restoration-audit

## What is here

- `paper/tex/` — manuscript source
- `paper/figs/` — the R code that draws the figures and writes the printed numbers
- `paper/evidence/` — a file list with SHA-256 hashes
- `data/` — the 20 data files named in that list

## Not included

This archive leaves out one extra file named in the paper's evidence list. The paper does not take any number from it.

- A private working note. The paper does not use any number from it. Those facts are already in the methods and in the result files included here.

## Rebuild

```bash
bash build.sh
```

The build checks every data file against its hash and stops if a file has
changed. Figures and printed numbers are generated from those files, not typed
in by hand.

Requires `python3`, `Rscript` with `digest`, `ggplot2`, `jsonlite`, `patchwork`
and `systemfonts`, and a TeX distribution with `latexmk`.

## Status

Working draft. Not submitted to any venue.

## Licence

Code: MIT (`LICENSE`). Manuscript text, figures and recorded result data:
CC BY 4.0 (`LICENSE-CONTENT`).
