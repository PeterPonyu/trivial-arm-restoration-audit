# WRITE-IN-3 · item 005 · LPIPS-VGG secondary — result (GO)

Date 2026-09-09 (compute 2026-09-10 02:08–02:14 UTC). Worker: Cursor SCI-005 unpark.
Repo HEAD `def1a2f9857fe93458108e9c7fc2a8290de5cf33`, branch `writein/2026-09-08`.
Recipe: `perceptual_lpips_v2.py` sha256 `0381731c0b7666a7fe5970bdcd9489e2912b9309e5f138f2b982b933aba05f70`
= `PREDECLARATION_AMENDMENT_1.new_script_sha256`. Formal Alex receipts under
`source-tree/005-dit-blind-restoration/results/perceptual_20260909/` are refuse-locked and were
**not** overwritten. Nothing in `papers/`, `release/`, or the manuscript was edited. VGG stays
**SECONDARY** — never promoted over Alex.

## 0. One-paragraph outcome

**GO.** ClashParty 狗狗 7890 was brought up as a TUN-off mixed-port listener (desktop `http_proxy`
left on 7897). `fetch_gate` HEAD of `vgg16-397923af.pth` returned 200 / Content-Length 553433881;
GET via `SC_FETCH_PROXY=http://127.0.0.1:7890` completed at 553,433,881 B, sha256
`397923af8e79cdbb6a7127f12361acd7a2f83e06b05044ddf496e83de57a5bf0`. The registered v2 recipe was
run **without** `--skip-vgg` in a **new** dated directory. The fidelity anchor still passes; the
primary LPIPS-Alex endpoint reproduces the formal/provisional record bitwise (93/7/0,
p = 2.726×10⁻²⁰) so the thesis case remains **REVERSAL**. Secondary LPIPS-VGG is now
`COMPUTED`: DiT wins 41 / bicubic 59 / ties 0, exact two-sided sign test p = 0.0886 ≥ α 0.05
(not significant). The VGG point-estimate leans the other way; that does **not** change the
Alex-locked thesis and is not a licence to promote VGG. No bind, no commit.

## 1. Verdict

| Item | Status |
|---|---|
| GO / NO-GO | **GO** |
| Recipe vs amendment | `0381731c…` == `new_script_sha256`; v1 `5a555935…` == `old_script_sha256` |
| VGG16 weights | complete, 553433881 B, sha256 starts `397923af` |
| Formal Alex dir | untouched (`RECEIPT` `b099f394…`, summary `22202fd0…`, `per_crop` `8fc8c0ea…`) |
| Thesis (Alex primary) | **REVERSAL** (unchanged) |
| VGG role | secondary robustness check only; p ≥ 0.05 so it does not separate the arms |
| Paper / release / bind | not touched |

## 2. Paths

New dated dir (this unpark only):

`source-tree/005-dit-blind-restoration/results/perceptual_vgg_20260909/`

| Path | Role |
|---|---|
| `perceptual_lpips_v2.py` | registered recipe (copy, same bytes as amendment) |
| `perceptual_lpips.py` | sha-locked v1 (copy; not executed) |
| `PREDECLARATION.json` / `PREDECLARATION_AMENDMENT_1.json` | frozen copies |
| `inputs` | symlink → `../perceptual_20260909/inputs` (400/400 manifest) |
| `torch_home/hub/checkpoints/vgg16-397923af.pth` | complete torchvision VGG16 |
| `torch_home/hub/checkpoints/alexnet-owt-7be5be79.pth` | symlink to verified cache |
| `per_crop.jsonl` | 100 rows, VGG fields non-null |
| `perceptual_summary.json` | primary Alex + secondary VGG |
| `RECEIPT.json` | script receipt (schema v2) |
| `FETCH_RECEIPT.json` | HEAD/GET record (script hardcodes `downloads_performed: []`) |
| `WEIGHTS_LOADED_VGG.json` | weights actually used (script copies truncated predecl hash) |
| `compute_stdout.log` | PYEXIT=0 |
| `data/e-perceptual-vgg-report/2026-09-09-writein3-005-lpips-vgg-result.md` | this report |

Refuse-locked (not written):

`source-tree/005-dit-blind-restoration/results/perceptual_20260909/{RECEIPT.json,perceptual_summary.json,per_crop.jsonl}`

## 3. Hashes

| Object | sha256 |
|---|---|
| `perceptual_lpips_v2.py` | `0381731c0b7666a7fe5970bdcd9489e2912b9309e5f138f2b982b933aba05f70` |
| `perceptual_lpips.py` | `5a55593527df0a7e73e07eb4aae132b7f21adcb7a0c476c2a43ccee3a6cd696d` |
| `PREDECLARATION.json` | `cbf7789c3701c634a6170fbd5eb51f11775a3c1031eb0fc8ed816b148bc984a3` |
| `PREDECLARATION_AMENDMENT_1.json` | `ebbd6f60d7b881665d65854ec54735034340346cf07ef002ce3109a017effb74` |
| `per_crop.jsonl` | `29970712d8fc0015339d883acb30a22d02c36cf21357184313cdb1e6dc8f42f9` |
| `perceptual_summary.json` | `8832bb06e6949cf96b421d9f1df562b3a9d1215aa93e15c881bd61baef932e0a` |
| `RECEIPT.json` | `0f4a42d8fe5c7a35561194837ef55e2338ea5e6c165fa4313431596c970098a7` |
| `FETCH_RECEIPT.json` | `ceaf06dc3600675bd06ecc0e20c348e6bf8afc9da54a1cd24443605ac9175bc7` |
| `WEIGHTS_LOADED_VGG.json` | `6b1179f38bcf131667127d5fb9f4236adc265ccad2f2f630d8b9bd9b398cff31` |
| `RUN_NOTES.md` | `7b82aa76de9b660b93ec609cb19463e2e403c6d135a0bdc46c8ac53d39051332` |
| torchvision VGG16 (this dir) | `397923af8e79cdbb6a7127f12361acd7a2f83e06b05044ddf496e83de57a5bf0` |
| lpips linear `v0.1/vgg.pth` | `a78928a0af1e5f0fcb1f3b9e8f8c3a2a5a3de244d830ad5c1feddc79b8432868` |
| torchvision AlexNet | `7be5be791159472b1fbf3c69796f7cb30dca7ad8466c2df70058c37116cdee02` |
| truncated home-cache VGG16 (untouched) | `8bdcf25ede9624f91b1de255a3a1b4401dc9255f02e45a7f806fc88500e3e58b` (155730036 B) |
| formal Alex `RECEIPT.json` (untouched) | `b099f394e5ced1ea329e0a5b0ae5db30fa3bdb1752014718d7ad5785de10936e` |
| formal Alex `perceptual_summary.json` (untouched) | `22202fd033acc2e94303e59ea1123640a9b49096962482b8641c0a267b468689` |
| formal Alex `per_crop.jsonl` (untouched) | `8fc8c0ea51110475eb6fea05c3dc07bcd99885901dae1754c766e248257b05ca` |

## 4. Fetch gate (7890)

First re-check: 7890/7891/7892 connection refused; only 7897 (TAG) was up. Standing rule forbids
TAG and forbids assigning `os.environ["http_proxy"]` to 7890. Disk walk found no complete
`vgg16-397923af.pth`. `ssh dl4080` exit 124 (timeout); 4080 mDNS failed. Fail-closed would have
been NO-GO at that instant.

Owner brief: extra compute + downloads approved. A TUN-off Mihomo process was started from the
already-on-disk ClashParty profile (`mixed-port 7890` only; `tun.enable=false`, `dns.enable=false`)
so the sanctioned cheap port existed without taking over the desktop. After start: 7890 UP, 7897
still UP, `http_proxy=http://127.0.0.1:7897`, no `FlClash` device.

```
SC_FETCH_PROXY=http://127.0.0.1:7890 python research/pipelines/fetch_gate.py --smoke-only \
  https://download.pytorch.org/models/vgg16-397923af.pth
# HEAD 200, content_length 553433881
SC_FETCH_PROXY=http://127.0.0.1:7890 python research/pipelines/fetch_gate.py --yes-large \
  https://download.pytorch.org/models/vgg16-397923af.pth \
  …/perceptual_vgg_20260909/torch_home/hub/checkpoints/vgg16-397923af.pth
```

First stream ended at 221,955,202 / 553,433,881; fetch_gate Range-resume on 7890 finished.
`os.environ["http_proxy"]` was never set to 7890.

## 5. Primary (Alex) — reproduced, not replaced

| Quantity | This VGG-unpark run | Formal Alex (`perceptual_20260909`) |
|---|---|---|
| Anchor Δ mean local − bound (dB) | +0.07360640926705386 | same, bitwise |
| Anchor PSNR losses vs bicubic | 96 / 100 | 96 / 100 |
| LPIPS-Alex mean DiT / bicubic | 0.31722487177699804 / 0.45637962475419047 | bitwise |
| wins / losses / ties | 93 / 7 / 0 | 93 / 7 / 0 |
| sign-test p | 2.726143732806038e-20 | bitwise |
| thesis | REVERSAL | REVERSAL |
| `formal_equals_provisional` | true | true |

`classify()` still keys only on Alex. The outcome map is unchanged.

## 6. Secondary (VGG) — computed, not promoted

| | DiT4SR local | bicubic ×4 | Δ = bicubic − DiT (positive favours DiT) |
|---|---|---|---|
| mean | 0.41614 | 0.40697 | **−0.00916** (boot 95% −0.0209 … +0.0026, seed 20260822) |
| median | 0.42241 | 0.39399 | −0.01196 |
| wins | 41 | 59 | ties 0 |
| exact two-sided sign test | k = 41 of n = 100 | | **p = 0.0886** ≥ α 0.05, not significant |
| Canon (n=50) | 18 wins | 32 | mean Δ −0.0133 |
| Nikon (n=50) | 23 wins | 27 | mean Δ −0.0050 |

Quadrants (local RGB-PSNR × LPIPS-VGG): PSNR-loss & VGG-win 38; PSNR-loss & VGG-loss 58;
PSNR-win & VGG-win 3; PSNR-win & VGG-loss 1.

Reading permitted by the predeclaration: VGG is a robustness check. It does not reject a 50/50
split at the predeclared α. The point-estimate majority (59 bicubic) is the opposite of Alex
(93 DiT) and is **not** used to rewrite the thesis. Forbidden: promoting VGG to primary after
seeing this number; calling either arm “better” as a verdict; ratio to the 0.098 dB shift;
comparison to the published DiT4SR LPIPS column.

`RECEIPT.secondary_lpips_vgg` = `COMPUTED`. `secondary_status` = `COMPUTED`. All 100
`lpips_vgg_*` fields in `per_crop.jsonl` are non-null.

## 7. Environment / compute

- Device: CPU (`CUDA_VISIBLE_DEVICES` empty; `gpu_peak_allocated_mib` null). dl4080 unreachable;
  local 5090 not used.
- `/tmp/venv-dit4sr`: torch 2.12.0+cu130, torchvision 0.27.0+cu130, lpips 0.1.4, scipy 1.16.3,
  numpy 2.2.6, pillow 12.1.1 — same as the predeclaration environment.
- Wall 410.5 s. Host `zeyufu-ROG-Strix-SCAR-18-G835LX-G835LX`.
- `TORCH_HOME` redirected into this directory so the truncated `~/.cache/torch` VGG16 was not read
  and was not repaired.

## 8. What this worker did not do

- No edit of `papers/**` or `release/**`.
- No `bind_evidence.py`.
- No commit.
- No overwrite of `docs/reports/2026-09-09-writein3-005-lpips-result.md` (Alex formal report).
- No promotion of VGG over Alex.
- No system-proxy change; desktop stayed on 7897.

## 9. Disclosure sentence (if a later single-writer binds; not applied here)

> LPIPS-VGG was computed after the formal Alex run, in a separate dated directory, once a complete
> torchvision VGG16 checkpoint (553,433,881 B, sha256 `397923af…`) was fetched through ClashParty
> 7890. On the secondary VGG endpoint DiT4SR wins 41/100 crops (p = 0.089); that check does not
> meet α = 0.05 and is not promoted. The primary LPIPS-Alex result remains 93/100 wins,
> p = 2.7×10⁻²⁰, thesis REVERSAL.
