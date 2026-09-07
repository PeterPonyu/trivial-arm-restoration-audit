# Local paths rewritten before deposit

Some result files recorded the machine they ran on, including local folder
names. Those strings are not published. The copies in this archive were
rewritten before deposit. The left column names each class of string rather
than quoting it.

The rewrite changes path strings only. Numbers and table structure stay the
same. Longer matches are applied first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |
| a branch of the private repository named in a recorded instruction | `<private-branch>` |
| a private project status word | the ordinary word it stands for |

Both machine prefixes are removed before a file is mapped to its place in this
archive, so the same path recorded on two machines becomes the same archived
string. A study that never left one machine will only show some of these
substitutions.

The last two rows rewrite recorded values, never keys. A reader comparing an
archived file with the original should see the same fields and the same
numbers; only a local name is changed.

## What was checked

Every rewritten file was read again after substitution and compared with the
original after all string values were blanked. A changed number, a dropped
field, a reordered list or a lost record stops the export. For line-oriented
files the line count is compared as well.

## Files rewritten

The hash on the left is the file as the run wrote it. The hash on the right is
the file in this archive, and it is the one the file list names and the build
checks.

| path | path substitutions | receipt-link refreshes | original sha256 | archived sha256 |
|---|---:|---:|---|---|
| `data/e-withdrawn/paper_measurement_toy_matched_budget.json` | 3 | 0 | `86cd354d3755cd5c…` | `7363376c6b16e0a4…` |
| `data/e-static/static.json` | 1 | 0 | `796a625165ef89fc…` | `c8f6eea65f526592…` |
| `data/e-naive/naive.json` | 1 | 0 | `60e471d87da0a806…` | `83a46f404e0f1c18…` |
| `data/e-simple/simple.json` | 1 | 0 | `3c1dcc256d343228…` | `ffa2fb4863926cc6…` |
| `data/e-eval/sota_dit4sr_eval.json` | 16 | 0 | `edf199d9ff933899…` | `749af50fc0e86631…` |
| `data/e-eval-earlier/sota_dit4sr_eval_20260816T062908Z.json` | 14 | 0 | `02a45088e6bf89d8…` | `06fd3b65c5ae9b41…` |
| `data/e-skip/complement_dit4sr_skip_census.json` | 2 | 0 | `4b8b3782939fb14c…` | `1409232fa989e43e…` |
| `data/e-sizes/complement_dit4sr_lq_size_histogram.json` | 2 | 0 | `564db0f199545884…` | `30695b5cd548443a…` |
| `data/e-orphans/complement_dit4sr_13stem_identity.json` | 16 | 0 | `9ae6a47f8f0e5a74…` | `5d4bfb206a23f8dc…` |
| `data/e-primary/paper_primary.json` | 1 | 0 | `4e43b7e0a78cf196…` | `97e416747aa78a65…` |
