# Redaction of recorded paths and internal names

The result files in this archive were written by the runs that produced them,
and they recorded where they were running and how the work was coordinated.
Those strings describe a private machine and a private workspace and are not
published, so the archived copies were rewritten before deposit. Describing the
rules below without reproducing the strings they remove is the point of this
file, so the left column names each class of string rather than quoting it.

The rewrite is textual and total: it substitutes path strings and internal
names and refreshes the explicit source/hash links in derived receipts, without
changing a numeric or structural value. Rules are applied longest match first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |
| a branch of the private repository named in a recorded instruction | `<private-branch>` |
| a disposition label of the private workspace's own series | the plain word it stands for |

Both machine prefixes are removed before an archived artifact is mapped to its
new location, so a path recorded on the rented machine and the same path
recorded locally become the same archived string rather than two. The rules are
the full declared set; a direction whose runs never left one machine will show
substitutions for only some of them.

The last two classes rewrite recorded values, never keys. A reader comparing an
archived record against the original finds the same schema and the same numbers;
what changes is a name that only resolves inside the workspace that coined it.

## What was checked

Every rewritten file was reparsed after substitution and compared against the
original with all string leaves erased. A changed number, a dropped key, a
reordered list or a lost record fails the export rather than being deposited.
For line-oriented records the record count is compared as well.

## Files rewritten

The digest on the left is the file as the run wrote it; the digest on the right
is the file in this archive, and it is the one the manifest binds and the build
verifies.

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
