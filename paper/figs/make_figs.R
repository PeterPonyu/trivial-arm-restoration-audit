# Figure entry point for 005. Emits into figs/out/.
# Refuses to draw anything that is not bound in evidence/evidence_manifest.json.
#
# Side effect by design: this script also writes tex/generated_numbers.tex and
# the generated result tables. Every quantity the manuscript prints comes from
# here, so prose cannot drift away from the bytes that were hashed.
#
# The work is split so that each file has one reason to change: figs/lib holds
# reading, joining, statistics and formatting; figs/panels holds one figure
# each; this file holds the order they run in and the checks that must pass
# before any of them run.
#
# Run from the paper directory:  Rscript figs/make_figs.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(jsonlite)
})

for (unit in c("rtx_theme.R", "lib/evidence.R", "lib/arms.R", "lib/stats.R", "lib/emit.R")) {
  source(file.path("figs", unit))
}

dir.create(file.path("figs", "out"), showWarnings = FALSE, recursive = TRUE)

manifest <- load_manifest()
read_bound <- evidence_reader(manifest, find_repo_root())
read_bound_lines <- evidence_lines_reader(manifest, find_repo_root())

toy <- read_bound("E-TOY")
longer <- read_bound("E-LONGER")
withdrawn <- read_bound("E-WITHDRAWN")
tier_static <- read_bound("E-STATIC")
tier_naive <- read_bound("E-NAIVE")
tier_simple <- read_bound("E-SIMPLE")

dit <- read_bound("E-DIT")
bicubic <- read_bound("E-BICUBIC")
nearest <- read_bound("E-NEAREST")
bicubic_audit <- read_bound("E-BICUBIC-AUDIT")
dit_earlier <- read_bound("E-DIT-EARLIER")
summary_rec <- read_bound("E-SUMMARY")
strata <- read_bound("E-STRATA")

eval_now <- read_bound("E-EVAL")
eval_then <- read_bound("E-EVAL-EARLIER")
census <- read_bound("E-SKIP")
sizes <- read_bound("E-SIZES")
orphans <- read_bound("E-ORPHANS")

tier_primary <- read_bound("E-PRIMARY")
tier_sota <- read_bound("E-SOTA")

# The two predeclared 2026-09-09 results. The perceptual pass scores a fresh
# local sample of the released model on the same crops; the ablation retrains
# the toy transformer under three initialisations. Both are read with their
# predeclarations so the checks below can hold the result to the rule that was
# frozen before it existed.
perc_predecl <- read_bound("E-PERCEPTUAL-PREDECL")
perc_amend <- read_bound("E-PERCEPTUAL-AMEND")
perc <- read_bound("E-PERCEPTUAL")
perc_rows <- read_bound_lines("E-PERCEPTUAL-RAW")
perc_receipt <- read_bound("E-PERCEPTUAL-RECEIPT")
perc_prov <- read_bound("E-PERCEPTUAL-PROVENANCE")

# Later dated VGG secondary. Formal Alex files stay the primary record; these
# rows are a backbone-sensitivity check and must not rewrite the thesis.
vgg <- read_bound("E-PERCEPTUAL-VGG")
vgg_rows <- read_bound_lines("E-PERCEPTUAL-VGG-RAW")
vgg_receipt <- read_bound("E-PERCEPTUAL-VGG-RECEIPT")
vgg_fetch <- read_bound("E-PERCEPTUAL-VGG-FETCH")
vgg_weights <- read_bound("E-PERCEPTUAL-VGG-WEIGHTS")
if (!"E-PERCEPTUAL-VGG-REPORT" %in% manifest$entries$id) {
  stop("the VGG write-in report is not bound")
}

init_predecl <- read_bound("E-INIT-PREDECL")
init_sum <- read_bound("E-INIT")
init_analysis <- read_bound("E-INIT-ANALYSIS")
init_receipt <- read_bound("E-INIT-RECEIPT")

# 2026-09-10 leftover labelled checks. Secondary / sensitivity only. The PDF
# is bound but is not JSON, so it is digest-checked rather than parsed here.
pub_predecl <- read_bound("E-PUBTABLE-PREDECL")
pub <- read_bound("E-PUBTABLE")
pub_receipt <- read_bound("E-PUBTABLE-RECEIPT")
leftover_predecl <- read_bound("E-CENSUS-LEFTOVER-PREDECL")
leftover <- read_bound("E-CENSUS-LEFTOVER")
leftover_receipt <- read_bound("E-CENSUS-LEFTOVER-RECEIPT")
if (!"E-PUBTABLE-PDF" %in% manifest$entries$id) {
  stop("the hashed supplementary PDF is not bound")
}

## ---------------------------------------------------------------------------
## Checks that must hold before anything is drawn. Each one is a sentence the
## manuscript makes, enforced here so it cannot survive the evidence changing.
## ---------------------------------------------------------------------------

toy_rows <- toy_arms(toy, longer)
TOY_N <- toy$metrics$`unet_result.json`$eval$n_test_pairs

# The ladder entries are one-line restatements of the toy record. If they ever
# stop restating it, the manuscript would be quoting a summary of something else.
if (!isTRUE(all.equal(tier_static$metrics$degraded_input_psnr_mean, toy_rows$psnr[1])) ||
    !isTRUE(all.equal(tier_naive$metrics$restored_psnr_mean, toy_rows$psnr[2])) ||
    !isTRUE(all.equal(tier_simple$metrics$restored_psnr_mean, toy_rows$psnr[4]))) {
  stop("the comparison ladder no longer restates the toy record it cites")
}

# The withdrawal is the paper's main documentary source for the toy scale, so it
# has to be quoting the same run the toy record holds.
if (!identical(as.integer(withdrawn$unet_n_params), as.integer(toy_rows$params[2])) ||
    !identical(as.integer(withdrawn$dit_n_params), as.integer(toy_rows$params[4]))) {
  stop("the withdrawal record and the toy record disagree on parameter counts")
}
if (!isTRUE(all.equal(withdrawn$counterevidence$unet_500step_orphan$restored_psnr_mean,
                      toy_rows$psnr[3]))) {
  stop("the withdrawal record and the unpromoted longer run disagree")
}

# Two paths hold the bicubic arm. Comparing digests says whether that is a second
# record or a second copy; comparing rows says whether they still agree either
# way. The manuscript reports which of the two it is rather than assuming.
assert_arms_agree(bicubic, bicubic_audit, "bicubic")
BICUBIC_IS_COPY <- identical(bound_digest(manifest, "E-BICUBIC"),
                             bound_digest(manifest, "E-BICUBIC-AUDIT"))

crops <- join_crops(dit = dit, bicubic = bicubic, nearest = nearest)
SUBSET_N <- nrow(crops)
crops$camera <- camera_of(crops$stem)
crops$d_bicubic <- crops$dit_psnr - crops$bicubic_psnr
crops$d_nearest <- crops$dit_psnr - crops$nearest_psnr

# Every mean the summary prints has to be the mean of the rows it summarises,
# and every recorded denominator has to describe the same paired population.
# Keep all four metrics in this check: guarding only RGB PSNR would let a stale
# SSIM or luma column reach the table and the new cross-metric panel.
summary_metric_columns <- c(
  rgb_psnr = "psnr",
  rgb_ssim = "ssim",
  y_psnr_shave4 = "ypsnr",
  y_ssim_shave4 = "yssim"
)
for (arm in c("dit", "bicubic", "nearest")) {
  for (metric_name in names(summary_metric_columns)) {
    crop_column <- paste0(arm, "_", summary_metric_columns[[metric_name]])
    recorded <- summary_rec[[arm]][[metric_name]]
    assert_recorded_mean(crops[[crop_column]], recorded$mean,
                         paste(arm, metric_name, "summary"))
    if (!identical(as.integer(recorded$n), SUBSET_N)) {
      stop(arm, " ", metric_name,
           ": the summary counts a different number of crops than the rows hold")
    }
  }
}
assert_recorded_mean(crops$dit_psnr, dit$bootstrap$rgb_psnr$mean, "method bootstrap")
assert_recorded_mean(crops$bicubic_psnr, bicubic$bootstrap$rgb_psnr$mean, "bicubic bootstrap")
assert_recorded_mean(crops$nearest_psnr, nearest$bootstrap$rgb_psnr$mean, "nearest bootstrap")

recorded_gap <- summary_rec$paired_delta_dit_minus_bicubic$rgb_psnr
if (!isTRUE(all.equal(mean(crops$d_bicubic), recorded_gap$mean_delta)) ||
    !isTRUE(all.equal(min(crops$d_bicubic), recorded_gap$min)) ||
    !isTRUE(all.equal(max(crops$d_bicubic), recorded_gap$max))) {
  stop("the recorded paired difference does not come from the per-crop rows")
}

wins_bicubic <- win_counts(crops$dit_psnr, crops$bicubic_psnr)
wins_nearest <- win_counts(crops$dit_psnr, crops$nearest_psnr)
recorded_wins <- strata$win_rate_dit_vs_bicubic_rgb_psnr
if (!identical(as.integer(wins_bicubic$wins), as.integer(recorded_wins$wins)) ||
    !identical(as.integer(wins_bicubic$losses), as.integer(recorded_wins$losses)) ||
    !identical(as.integer(wins_bicubic$ties), as.integer(recorded_wins$ties))) {
  stop("the recorded win and loss counts do not come from the per-crop rows")
}

CAMERAS <- sort(unique(crops$camera))
by_camera <- lapply(CAMERAS, function(name) {
  rows <- crops[crops$camera == name, ]
  counts <- win_counts(rows$dit_psnr, rows$bicubic_psnr)
  recorded <- strata$camera_strata[[name]]
  if (!identical(as.integer(counts$wins), as.integer(recorded$wins)) ||
      !identical(as.integer(counts$losses), as.integer(recorded$losses))) {
    stop(name, ": the recorded stratum counts do not come from the per-crop rows")
  }
  if (!isTRUE(all.equal(mean(rows$d_bicubic), recorded$mean_delta))) {
    stop(name, ": the recorded stratum mean does not come from the per-crop rows")
  }
  ci <- bootstrap_mean(rows$d_bicubic)
  data.frame(camera = name, n = counts$n, wins = counts$wins, losses = counts$losses,
             mean_delta = mean(rows$d_bicubic), lower = ci[1], upper = ci[2],
             stringsAsFactors = FALSE)
})
by_camera <- do.call(rbind, by_camera)

# The census describes an attempt on the full input set. The path it names has
# since been rewritten by the subset run, and only the retained snapshot still
# matches it, so the snapshot is what the census is checked against.
if (!identical(as.integer(census$n_lq), as.integer(eval_then$n_lq)) ||
    !identical(as.integer(census$n_run), as.integer(eval_then$n_run)) ||
    !identical(as.integer(census$n_skipped_oom), as.integer(eval_then$n_skipped_oom))) {
  stop("the skip census does not describe the retained snapshot of the attempt it counts")
}
if (!identical(as.integer(census$n_run + census$n_skipped_oom), as.integer(census$n_total))) {
  stop("the skip census does not account for every input")
}
CENSUS_MATCHES_LIVE_PATH <- identical(as.integer(census$n_lq), as.integer(eval_now$n_lq))

if (!identical(as.integer(nrow(orphans$stems)), as.integer(census$n_run))) {
  stop("the outputs of the earlier attempt are not the ones the census counted")
}
if (any(!is.na(orphans$stems$gt_path))) {
  stop("an output of the earlier attempt is recorded with a reference image; the paper says none has one")
}

## ---------------------------------------------------------------------------
## The measurements.
## ---------------------------------------------------------------------------

TOY_REFERENCE <- toy_rows$psnr[toy_rows$kind == "reference"]
TOY_SPEED_RATIO <- toy_rows$seconds[2] / toy_rows$seconds[4]
TOY_PARAM_EXCESS <- toy_rows$params[4] / toy_rows$params[2] - 1
TOY_LOSS_DROP <- toy_rows$final_loss[2] / toy_rows$final_loss[3]

# The manuscript calls the longer run "ten times the budget" in three places. The
# word is spelled out here so that a change to either step count either changes
# the word or stops the build; a ratio that stops being whole would do the latter.
BUDGET_MULTIPLE <- toy_rows$steps[3] / toy_rows$steps[2]
if (BUDGET_MULTIPLE != round(BUDGET_MULTIPLE)) {
  stop("the longer run is no longer a whole multiple of the shorter one")
}

gap_sign <- sign_test(crops$d_bicubic)
gap_wilcox <- wilcoxon_paired(crops$dit_psnr, crops$bicubic_psnr)
gap_t <- paired_t(crops$dit_psnr, crops$bicubic_psnr)
gap_ci <- bootstrap_mean(crops$d_bicubic)
gap_nearest_sign <- sign_test(crops$d_nearest)

noise <- run_to_run(dit_earlier, dit)
NOISE_MARGIN <- noise_margin(mean(crops$d_bicubic), noise$max_abs)

SKIPPED_PIXELS <- prod(sizes$bins$upscaled_hw[[2]])
BUDGET_EXCESS <- SKIPPED_PIXELS / census$vram_budget$max_upscaled_pixels
SKIPPED_BY_CAMERA <- unlist(sizes$skipped_camera_prefix_counts)
SKIPPED_CAMERAS <- length(SKIPPED_BY_CAMERA)
SURVIVING_CAMERAS <- length(CAMERAS)
CENSUS_SKIP_SHARE <- census$n_skipped_oom / census$n_total

skipped_frame <- data.frame(camera = names(SKIPPED_BY_CAMERA),
                            n = as.integer(SKIPPED_BY_CAMERA),
                            stringsAsFactors = FALSE)
skipped_frame <- skipped_frame[order(-skipped_frame$n, skipped_frame$camera), ]
skipped_frame$measured <- ifelse(skipped_frame$camera %in% CAMERAS, "yes", "no")

if (sum(skipped_frame$n) != census$n_skipped_oom) {
  stop("the per-group breakdown does not add up to the number of inputs dropped")
}

# A cross-metric view of the same paired population. Keep PSNR and SSIM on
# their native scales: decibels and a unitless similarity score are not
# commensurate effect sizes. The panel uses these rows for a descriptive
# consistency check only; it adds no new evidence source or inferential test.
metric_specs <- data.frame(
  metric = c("RGB", "Y", "RGB", "Y"),
  unit = c("PSNR (dB)", "PSNR (dB)", "SSIM (unitless)", "SSIM (unitless)"),
  method_column = c("dit_psnr", "dit_ypsnr", "dit_ssim", "dit_yssim"),
  baseline_column = c("bicubic_psnr", "bicubic_ypsnr", "bicubic_ssim", "bicubic_yssim"),
  stringsAsFactors = FALSE
)

metric_effects <- do.call(rbind, lapply(seq_len(nrow(metric_specs)), function(i) {
  spec <- metric_specs[i, ]
  differences <- crops[[spec$method_column]] - crops[[spec$baseline_column]]
  if (length(differences) != SUBSET_N || any(!is.finite(differences))) {
    stop(spec$unit, " ", spec$metric,
         ": paired metric vector is missing, non-finite, or has the wrong length")
  }
  mean_delta <- mean(differences)
  interval <- bootstrap_mean(differences)
  if (length(interval) != 2L || any(!is.finite(interval))) {
    stop(spec$unit, " ", spec$metric, ": bootstrap interval is not finite")
  }
  if (!(interval[1] <= mean_delta && mean_delta <= interval[2])) {
    stop(spec$unit, " ", spec$metric,
         ": bootstrap interval does not contain its paired mean")
  }
  data.frame(metric = spec$metric, unit = spec$unit, n = length(differences),
             mean_delta = mean_delta, lower = interval[1], upper = interval[2],
             stringsAsFactors = FALSE)
}))
metric_effects$metric <- factor(metric_effects$metric, levels = c("Y", "RGB"))
metric_effects$unit <- factor(metric_effects$unit,
                              levels = c("PSNR (dB)", "SSIM (unitless)"))
if (nrow(metric_effects) != 4L || any(metric_effects$n != SUBSET_N)) {
  stop("cross-metric effect table does not contain one complete row per metric")
}

## ---------------------------------------------------------------------------
## The perceptual pass. Every sentence the manuscript makes about it is held
## here to the predeclaration, to the per-crop rows and to the bound fidelity
## record, so the reversal cannot survive any of them changing.
## ---------------------------------------------------------------------------

anchor <- perc$anchor_check
lp <- perc$primary_lpips_alex

# The perceptual pass scored a fresh sample of the released model, not the
# pixel set behind the bound fidelity table. The predeclared anchor rule says
# when that sample may be read alongside the bound ranking: its mean fidelity
# within half a decibel of the bound record, and losing to bicubic on at least
# ninety crops. Both halves are re-evaluated here rather than trusted.
if (!identical(perc$anchor_result, "PASS") || !isTRUE(anchor$passed)) {
  stop("the perceptual pass records its fidelity anchor as failed; the reversal may not be read alongside the bound ranking")
}
if (!isTRUE(all.equal(anchor$bound_rgb_psnr_mean, mean(crops$dit_psnr)))) {
  stop("the perceptual pass anchored to a fidelity mean that is not the bound record's")
}
ANCHOR_DELTA <- anchor$local_rgb_psnr_mean - anchor$bound_rgb_psnr_mean
if (!isTRUE(all.equal(ANCHOR_DELTA, anchor$delta_mean_local_minus_bound_db))) {
  stop("the recorded anchor shift is not the difference of the two means it names")
}
if (abs(ANCHOR_DELTA) > 0.5) stop("fidelity anchor: the fresh sample is more than half a decibel from the bound record")
if (anchor$local_losses_vs_bicubic_rgb_psnr < 90) stop("fidelity anchor: the fresh sample loses to bicubic on fewer than ninety crops")

# The per-crop rows are the record; the summary must restate them.
if (nrow(perc_rows) != SUBSET_N || !identical(as.integer(lp$sign_test$n), SUBSET_N)) {
  stop("the perceptual pass does not cover the same number of crops as the bound subset")
}
if (!setequal(perc_rows$crop, crops$stem)) {
  stop("the perceptual pass scored different crops from the bound fidelity rows")
}
perc_rows <- perc_rows[match(crops$stem, perc_rows$crop), ]
if (any(abs(perc_rows$`rgb_psnr_dit_bound_E-DIT` - crops$dit_psnr) > 1e-9) ||
    any(abs(perc_rows$rgb_psnr_bicubic - crops$bicubic_psnr) > 1e-9)) {
  stop("the perceptual pass carries bound fidelity values that do not match the bound rows")
}
perc_rows$d_lpips <- perc_rows$lpips_alex_bicubic - perc_rows$lpips_alex_dit
if (any(abs(perc_rows$d_lpips - perc_rows$delta_lpips_alex_bicubic_minus_dit) > 1e-9)) {
  stop("the recorded perceptual difference is not bicubic minus the released model")
}
perc_rows$d_psnr_local <- perc_rows$rgb_psnr_dit_local - perc_rows$rgb_psnr_bicubic
if (any(abs(perc_rows$d_psnr_local - perc_rows$delta_rgb_psnr_dit_minus_bicubic) > 1e-9)) {
  stop("the recorded local fidelity difference is not the released model minus bicubic")
}
assert_recorded_mean(perc_rows$lpips_alex_dit, lp$dit_mean, "perceptual, released model")
assert_recorded_mean(perc_rows$lpips_alex_bicubic, lp$bicubic_mean, "perceptual, bicubic")
assert_recorded_mean(perc_rows$d_lpips, lp$mean_delta, "perceptual, paired difference")
assert_recorded_mean(perc_rows$rgb_psnr_dit_local, anchor$local_rgb_psnr_mean, "anchor, local fidelity")
if (sum(perc_rows$d_psnr_local < 0) != anchor$local_losses_vs_bicubic_rgb_psnr) {
  stop("the recorded anchor loss count does not come from the per-crop rows")
}

lpips_wins <- win_counts(perc_rows$lpips_alex_bicubic, perc_rows$lpips_alex_dit)
# win_counts is oriented as "first argument larger"; a larger bicubic distance is
# a win for the released model, which is the orientation the record uses.
if (!identical(as.integer(lpips_wins$wins), as.integer(lp$dit_wins)) ||
    !identical(as.integer(lpips_wins$losses), as.integer(lp$bicubic_wins)) ||
    !identical(as.integer(lpips_wins$ties), as.integer(lp$ties))) {
  stop("the recorded perceptual win and loss counts do not come from the per-crop rows")
}
lpips_sign <- sign_test(perc_rows$d_lpips)
if (abs(lpips_sign$p - lp$sign_test$p_two_sided) > 1e-6 * lp$sign_test$p_two_sided) {
  stop("the recorded sign test does not reproduce from the per-crop rows")
}
if (lp$dit_wins <= SUBSET_N / 2 || lpips_sign$p >= 1e-10) {
  stop("the perceptual rows no longer show the reversal the manuscript reports")
}
if (!identical(perc$thesis_case, "REVERSAL")) {
  stop("the perceptual pass records an outcome other than the reversal the manuscript is written for")
}
lpips_ci <- bootstrap_mean(perc_rows$d_lpips)
if (!(lpips_ci[1] <= lp$mean_delta && lp$mean_delta <= lpips_ci[2])) {
  stop("perceptual bootstrap interval does not contain its paired mean")
}
for (name in names(lp$camera_strata)) {
  rows <- perc_rows[perc_rows$camera == name, ]
  if (sum(rows$d_lpips > 0) != lp$camera_strata[[name]]$dit_wins) {
    stop(name, ": the recorded perceptual stratum count does not come from the per-crop rows")
  }
}

# The quadrants pair each crop's fidelity side with its perceptual side. They
# are recounted from the rows and must add up to the whole subset.
quad <- list(
  loss_win = sum(perc_rows$d_psnr_local < 0 & perc_rows$d_lpips > 0),
  loss_loss = sum(perc_rows$d_psnr_local < 0 & perc_rows$d_lpips < 0),
  win_win = sum(perc_rows$d_psnr_local > 0 & perc_rows$d_lpips > 0),
  win_loss = sum(perc_rows$d_psnr_local > 0 & perc_rows$d_lpips < 0)
)
recorded_quad <- perc$psnr_vs_perceptual_quadrants$lpips_alex
if (quad$loss_win != recorded_quad$psnr_loss_perceptual_win ||
    quad$loss_loss != recorded_quad$psnr_loss_perceptual_loss ||
    quad$win_win != recorded_quad$psnr_win_perceptual_win ||
    quad$win_loss != recorded_quad$psnr_win_perceptual_loss ||
    sum(unlist(quad)) != SUBSET_N) {
  stop("the recorded quadrant counts do not come from the per-crop rows")
}

# Provenance the manuscript discloses. The amendment was made after a
# provisional run had been seen; the formal run must reproduce it. The formal
# Alex files still record the secondary backbone as not computed; a later
# dated directory holds the VGG check and must not overwrite those files.
if (!isTRUE(perc$formal_equals_provisional) ||
    !isTRUE(perc$cross_check_vs_provisional$formal_equals_provisional)) {
  stop("the formal perceptual run does not reproduce the provisional run it was amended after")
}
if (!isTRUE(perc_amend$provisional_result_seen_before_amendment) ||
    !isTRUE(perc_amend$endpoints_unchanged) ||
    !isTRUE(perc_amend$amends$sha256 == perc$predeclaration$sha256) ||
    !identical(perc_receipt$compute_script$sha256, perc_amend$new_script_sha256)) {
  stop("the amendment record, the summary and the receipt do not describe one run")
}
if (!startsWith(perc$secondary_status, "NOT_COMPUTED")) {
  stop("the formal Alex summary no longer records VGG as not computed; the formal files were overwritten")
}
if (any(!is.na(perc_rows$lpips_vgg_dit)) || any(!is.na(perc_rows$lpips_vgg_bicubic))) {
  stop("formal Alex per-crop rows now carry a VGG value; the formal files were overwritten")
}

# VGG secondary: same crops, Alex primary reproduced, VGG scored, thesis
# still the Alex reversal. A significant VGG split would still be secondary;
# a non-significant one must not be promoted into a verdict.
if (!identical(vgg$thesis_case, "REVERSAL") || !identical(perc$thesis_case, "REVERSAL")) {
  stop("the VGG run or the formal Alex record no longer holds the Alex reversal")
}
if (!identical(vgg$secondary_status, "COMPUTED") ||
    !identical(vgg_receipt$secondary_lpips_vgg, "COMPUTED")) {
  stop("the later VGG directory does not record the secondary backbone as computed")
}
if (nrow(vgg_rows) != SUBSET_N || !setequal(vgg_rows$crop, crops$stem)) {
  stop("the VGG secondary pass scored different crops from the bound subset")
}
vgg_rows <- vgg_rows[match(crops$stem, vgg_rows$crop), ]
if (any(abs(vgg_rows$lpips_alex_dit - perc_rows$lpips_alex_dit) > 1e-6) ||
    any(abs(vgg_rows$lpips_alex_bicubic - perc_rows$lpips_alex_bicubic) > 1e-6)) {
  stop("the VGG run does not reproduce the formal Alex distances crop for crop")
}
if (any(is.na(vgg_rows$lpips_vgg_dit)) || any(is.na(vgg_rows$lpips_vgg_bicubic))) {
  stop("VGG per-crop rows still carry a null secondary value")
}
vgg_lp <- vgg$secondary_lpips_vgg
vgg_rows$d_lpips_vgg <- vgg_rows$lpips_vgg_bicubic - vgg_rows$lpips_vgg_dit
if (any(abs(vgg_rows$d_lpips_vgg - vgg_rows$delta_lpips_vgg_bicubic_minus_dit) > 1e-9)) {
  stop("the recorded VGG difference is not bicubic minus the released model")
}
assert_recorded_mean(vgg_rows$lpips_vgg_dit, vgg_lp$dit_mean, "VGG, released model")
assert_recorded_mean(vgg_rows$lpips_vgg_bicubic, vgg_lp$bicubic_mean, "VGG, bicubic")
assert_recorded_mean(vgg_rows$d_lpips_vgg, vgg_lp$mean_delta, "VGG, paired difference")
vgg_wins <- win_counts(vgg_rows$lpips_vgg_bicubic, vgg_rows$lpips_vgg_dit)
if (!identical(as.integer(vgg_wins$wins), as.integer(vgg_lp$dit_wins)) ||
    !identical(as.integer(vgg_wins$losses), as.integer(vgg_lp$bicubic_wins)) ||
    !identical(as.integer(vgg_wins$ties), as.integer(vgg_lp$ties))) {
  stop("the recorded VGG win and loss counts do not come from the per-crop rows")
}
vgg_sign <- sign_test(vgg_rows$d_lpips_vgg)
if (abs(vgg_sign$p - vgg_lp$sign_test$p_two_sided) > 1e-6) {
  stop("the recorded VGG sign test does not reproduce from the per-crop rows")
}
if (isTRUE(vgg_lp$sign_test$significant) || vgg_lp$sign_test$p_two_sided < 0.05) {
  stop("VGG now meets alpha; the manuscript must not silently keep the not-significant wording")
}
vgg_ci <- bootstrap_mean(vgg_rows$d_lpips_vgg)
if (!(vgg_ci[1] <= vgg_lp$mean_delta && vgg_lp$mean_delta <= vgg_ci[2])) {
  stop("VGG bootstrap interval does not contain its paired mean")
}
vgg_quad <- list(
  loss_win = sum(perc_rows$d_psnr_local < 0 & vgg_rows$d_lpips_vgg > 0),
  loss_loss = sum(perc_rows$d_psnr_local < 0 & vgg_rows$d_lpips_vgg < 0),
  win_win = sum(perc_rows$d_psnr_local > 0 & vgg_rows$d_lpips_vgg > 0),
  win_loss = sum(perc_rows$d_psnr_local > 0 & vgg_rows$d_lpips_vgg < 0)
)
recorded_vgg_quad <- vgg$psnr_vs_perceptual_quadrants$lpips_vgg
if (vgg_quad$loss_win != recorded_vgg_quad$psnr_loss_perceptual_win ||
    vgg_quad$loss_loss != recorded_vgg_quad$psnr_loss_perceptual_loss ||
    vgg_quad$win_win != recorded_vgg_quad$psnr_win_perceptual_win ||
    vgg_quad$win_loss != recorded_vgg_quad$psnr_win_perceptual_loss ||
    sum(unlist(vgg_quad)) != SUBSET_N) {
  stop("the recorded VGG quadrant counts do not come from the per-crop rows")
}
if (!identical(as.integer(vgg$primary_lpips_alex$dit_wins), as.integer(lp$dit_wins)) ||
    !identical(as.integer(vgg$primary_lpips_alex$bicubic_wins), as.integer(lp$bicubic_wins)) ||
    !isTRUE(all.equal(vgg$primary_lpips_alex$dit_mean, lp$dit_mean)) ||
    !isTRUE(vgg$formal_equals_provisional)) {
  stop("the later VGG run no longer reproduces the formal Alex primary")
}
if (!identical(vgg_receipt$compute_script$sha256, perc_amend$new_script_sha256)) {
  stop("the VGG run was not scored with the amended registered script")
}
if (!identical(as.integer(vgg_fetch$bytes), 553433881L) ||
    !identical(as.integer(vgg_weights$weights_loaded$torchvision_vgg16$bytes), 553433881L) ||
    !identical(vgg_fetch$sha256, vgg_weights$weights_loaded$torchvision_vgg16$sha256) ||
    !startsWith(vgg_fetch$sha256, "397923af")) {
  stop("the VGG fetch receipt and the loaded-weights sidecar do not name one complete checkpoint")
}
if (!identical(bound_digest(manifest, "E-PERCEPTUAL"),
               "22202fd033acc2e94303e59ea1123640a9b49096962482b8641c0a267b468689") ||
    !identical(bound_digest(manifest, "E-PERCEPTUAL-RECEIPT"),
               "b099f394e5ced1ea329e0a5b0ae5db30fa3bdb1752014718d7ad5785de10936e") ||
    !identical(bound_digest(manifest, "E-PERCEPTUAL-RAW"),
               "8fc8c0ea51110475eb6fea05c3dc07bcd99885901dae1754c766e248257b05ca")) {
  stop("formal Alex perceptual hashes drifted; VGG must not overwrite that directory")
}
LPIPS_SEED <- perc_prov$dit4sr_seed20260909$inference$seed
if (!is.numeric(LPIPS_SEED) || length(LPIPS_SEED) != 1L) stop("the sampling seed of the fresh sample is not recorded")
if (perc_prov$dit4sr_seed20260909$n != SUBSET_N || length(perc_receipt$downloads_performed) != 0L) {
  stop("the fresh sample does not cover the subset, or the run downloaded something the receipt should list")
}
if (!isTRUE(perc$predeclaration$declared_utc < perc$computed_utc) ||
    !isTRUE(perc_amend$amended_utc < perc$computed_utc)) {
  stop("the perceptual predeclaration or its amendment postdates the computation")
}

## ---------------------------------------------------------------------------
## The initialisation ablation. Nine cells; the reading rule that fired is
## re-derived from the cells under the predeclared threshold.
## ---------------------------------------------------------------------------

init_cells <- init_sum$cells
INIT_THRESHOLD <- init_sum$threshold_mean_last10_loss
INIT_MODES <- c("library_default", "dit_standard", "dit_zero")
if (nrow(init_cells) != init_predecl$design$cells || nrow(init_cells) != 9L ||
    !setequal(unique(init_cells$mode), INIT_MODES) ||
    !identical(as.integer(init_predecl$design$training$steps), 50L)) {
  stop("the initialisation ablation does not hold the nine predeclared cells")
}
if (!identical(init_receipt$rule_fired, init_sum$rule_fired) ||
    !identical(init_receipt$predeclaration_sha256, init_sum$predeclaration$sha256) ||
    !isTRUE(init_receipt$frozen_sources_all_match) ||
    !isTRUE(init_receipt$predeclaration_mtime_before_all_outputs) ||
    !identical(as.integer(init_receipt$cells_ok), 9L)) {
  stop("the ablation receipt, summary and predeclaration do not describe one run")
}
if (any((init_cells$mean_last10_loss >= INIT_THRESHOLD) != init_cells$stalls)) {
  stop("a cell's recorded stall flag disagrees with the predeclared threshold")
}
stalls_by_mode <- tapply(init_cells$stalls, init_cells$mode, sum)
seeds_by_mode <- tapply(init_cells$stalls, init_cells$mode, length)
if (any(seeds_by_mode != 3L)) stop("a mode does not hold three seeds")
for (m in INIT_MODES) {
  if (stalls_by_mode[[m]] != init_sum$modes[[m]]$seeds_stalling) {
    stop(m, ": the recorded number of stalling seeds does not come from the cells")
  }
}
if (stalls_by_mode[["library_default"]] != 3L || stalls_by_mode[["dit_standard"]] != 3L ||
    stalls_by_mode[["dit_zero"]] != 0L) {
  stop("the ablation cells no longer show the pattern the manuscript reports: default and standard stall, zero-gated escapes")
}
if (!identical(init_sum$rule_fired, "R1_INIT_DEPENDENT")) {
  stop("the ablation fired a reading rule other than the one the manuscript is written for")
}
# The predeclared attribution being tested names zero-initialised gates. The arm
# that carries exactly-zero gates must be the one recorded as such.
zero_probe <- tapply(init_cells$zero_target_all_exact_zero, init_cells$mode, all)
if (!isTRUE(zero_probe[["dit_zero"]]) || isTRUE(zero_probe[["library_default"]]) ||
    isTRUE(zero_probe[["dit_standard"]])) {
  stop("the initialisation probe does not place exact-zero gates on the arm the manuscript says carries them")
}
if (any(!init_cells$restored_below_identity)) {
  stop("an ablation cell reached the degraded input; the trivial-arm sentence about the toy is stale")
}
IDENTITY_PSNR <- unique(init_cells$degraded_input_psnr_mean)
if (length(IDENTITY_PSNR) != 1L || !isTRUE(all.equal(IDENTITY_PSNR, TOY_REFERENCE))) {
  stop("the ablation scored against a degraded input that is not the bound toy reference")
}
# library_default seed 0 is the bound toy construction; the record must
# reproduce it within the printed precision, or the toy sentences are stale.
repro <- init_cells[init_cells$mode == "library_default" & init_cells$seed == 0, ]
if (abs(repro$mean_last10_loss - toy_rows$last10_loss[4]) > 5e-4 ||
    abs(repro$final_loss - toy_rows$final_loss[4]) > 5e-4 ||
    abs(repro$restored_psnr_mean - toy_rows$psnr[4]) > 0.05) {
  stop("the ablation's default cell does not reproduce the bound toy record")
}

## ---------------------------------------------------------------------------
## Leftover labelled checks (2026-09-10). Secondary / sensitivity only.
## ---------------------------------------------------------------------------

if (!identical(pub$role, "labelled_sensitivity_not_thesis") || isTRUE(pub$paper_promotion)) {
  stop("the published-table check is no longer a labelled sensitivity")
}
if (!isTRUE(all.equal(pub$realsr$psnr[[length(pub$realsr$psnr)]], 23.378)) ||
    !isTRUE(all.equal(pub$source$sha256,
                      bound_digest(manifest, "E-PUBTABLE-PDF"))) ||
    !identical(bound_digest(manifest, "E-PUBTABLE-PDF"),
               "eef21f0722775b5c349f730848ea489ca10d7a5e227b513a72d818b94bb3bbcc")) {
  stop("the published DiT4SR cell or the hashed supplement drifted")
}
if (!isTRUE(all.equal(pub$alignment_bound$local_dit_y_psnr,
                      dit$bootstrap$y_psnr_shave4$mean)) ||
    !isTRUE(all.equal(pub$alignment_bound$published_dit_psnr, 23.378)) ||
    !isTRUE(all.equal(pub$alignment_bound$delta_y_db,
                      dit$bootstrap$y_psnr_shave4$mean - 23.378))) {
  stop("the published-table alignment no longer restates the bound luma mean")
}
if (!isTRUE(all.equal(pub$alignment_local_sample$local_dit_y_psnr,
                      perc$anchor_check$local_fidelity_bootstrap$y_psnr_shave4$mean))) {
  stop("the extra-sample published-table alignment no longer restates the local luma mean")
}
if (!identical(pub$drealsr$local_alignment, "not_computed")) {
  stop("a DrealSR local alignment was invented; extra scale without DiT outputs stays not computed")
}
if (!isTRUE(leftover$joined == FALSE) ||
    as.integer(leftover$stem_name_intersection_with_skip) != SUBSET_N ||
    as.integer(leftover$stem_name_intersection_with_ran) != 0L ||
    !setequal(leftover$stem_name_intersection, crops$stem)) {
  stop("the leftover census-versus-crop128 name check no longer matches the scored stems")
}
if (!isTRUE(leftover$orphans$any_gt == FALSE) ||
    !isTRUE(leftover$orphans$any_metric_computed == FALSE) ||
    as.integer(leftover$orphans$n) != nrow(orphans$stems)) {
  stop("the leftover orphan check invented a reference or a quality number")
}
if (isTRUE(leftover_receipt$quality_numbers_invented)) {
  stop("the leftover receipt no longer says no quality number was invented")
}
if (!identical(pub_predecl$declared_utc < pub$computed_utc, TRUE) ||
    !identical(leftover_predecl$declared_utc < leftover$computed_utc, TRUE)) {
  stop("a leftover predeclaration postdates its computation")
}
init_mode_loss <- tapply(init_cells$mean_last10_loss, init_cells$mode, mean)
init_mode_psnr <- tapply(init_cells$restored_psnr_mean, init_cells$mode, mean)
stalled_cells <- init_cells[init_cells$stalls, ]
escaped_cells <- init_cells[!init_cells$stalls, ]

## ---------------------------------------------------------------------------
## Figures. Each panel reads the objects above and writes one file.
## ---------------------------------------------------------------------------

for (unit in c("fig0_three_scales.R", "fig1_toy.R", "fig2_budget.R",
               "fig3_subset.R", "fig4_paired.R", "fig5_ceiling.R",
               "fig6_metric_consistency.R", "fig7_camera_sensitivity.R",
               "fig9_crop_camera_metrics.R", "fig10_perceptual_reversal.R",
               "fig11_init_ablation.R")) {
  source(file.path("figs", "panels", unit))
}

## ---------------------------------------------------------------------------
## Numbers and tables.
## ---------------------------------------------------------------------------

write_generated(c(
  macro("ToyN", TOY_N),
  macro("ToySeed", withdrawn$seed),
  macro("ToySteps", toy_rows$steps[2]),
  macro("ToyLongSteps", toy_rows$steps[3]),
  macro("BudgetMultiple", count_word(BUDGET_MULTIPLE)),
  macro("BudgetFold", paste0(count_word(BUDGET_MULTIPLE), "fold")),
  macro("ToyEvalSteps", toy$metrics$`unet_result.json`$eval$num_inference_steps),
  macro("ToyRuns", withdrawn$n_runs_per_model),
  macro("ToyDegraded", fmt(toy_rows$psnr[1])),
  macro("ToyDegradedSSIM", fmt(toy_rows$ssim[1], 3)),
  macro("ToyConv", fmt(toy_rows$psnr[2])),
  macro("ToyConvSSIM", fmt(toy_rows$ssim[2], 3)),
  macro("ToyLong", fmt(toy_rows$psnr[3])),
  macro("ToyLongSSIM", fmt(toy_rows$ssim[3], 3)),
  macro("ToyTrans", fmt(toy_rows$psnr[4])),
  macro("ToyTransSSIM", fmt(toy_rows$ssim[4], 3)),
  macro("ToyConvShortfall", fmt(toy_rows$psnr[1] - toy_rows$psnr[2])),
  macro("ToyTransShortfall", fmt(toy_rows$psnr[1] - toy_rows$psnr[4])),
  macro("ToyConvParams", thousands(toy_rows$params[2])),
  macro("ToyTransParams", thousands(toy_rows$params[4])),
  macro("ToyParamExcess", fmt(100 * TOY_PARAM_EXCESS, 1)),
  macro("ToyConvSeconds", fmt(toy_rows$seconds[2])),
  macro("ToyTransSeconds", fmt(toy_rows$seconds[4])),
  macro("ToySpeedRatio", fmt(TOY_SPEED_RATIO, 1)),
  macro("ToyConvLoss", fmt(toy_rows$final_loss[2], 4)),
  macro("ToyTransLoss", fmt(toy_rows$final_loss[4], 4)),
  macro("ToyTransLastTen", fmt(toy_rows$last10_loss[4], 4)),
  macro("ToyLongLoss", fmt(toy_rows$final_loss[3], 4)),
  macro("ToyLongSeconds", fmt(toy_rows$seconds[3])),
  macro("ToyLossDrop", fmt(TOY_LOSS_DROP, 1)),
  macro("ToyLongRegression", fmt(toy_rows$psnr[2] - toy_rows$psnr[3])),

  macro("SubsetN", SUBSET_N),
  macro("SubsetCameras", SURVIVING_CAMERAS),
  macro("MethodPSNR", fmt(mean(crops$dit_psnr))),
  macro("MethodSSIM", fmt(mean(crops$dit_ssim), 3)),
  macro("MethodLow", fmt(dit$bootstrap$rgb_psnr$low)),
  macro("MethodHigh", fmt(dit$bootstrap$rgb_psnr$high)),
  macro("BicubicPSNR", fmt(mean(crops$bicubic_psnr))),
  macro("BicubicSSIM", fmt(mean(crops$bicubic_ssim), 3)),
  macro("NearestPSNR", fmt(mean(crops$nearest_psnr))),
  macro("NearestSSIM", fmt(mean(crops$nearest_ssim), 3)),
  macro("MethodYPSNR", fmt(mean(crops$dit_ypsnr))),
  macro("BicubicYPSNR", fmt(mean(crops$bicubic_ypsnr))),
  macro("GapBicubic", signed(mean(crops$d_bicubic))),
  macro("GapBicubicAbs", fmt(abs(mean(crops$d_bicubic)))),
  macro("GapNearest", signed(mean(crops$d_nearest))),
  macro("GapSSIM", signed(mean(crops$dit_ssim - crops$bicubic_ssim), 3)),
  macro("GapLower", fmt(gap_ci[1])),
  macro("GapUpper", fmt(gap_ci[2])),
  macro("GapRecordedLower", fmt(strata$paired_delta_dit_minus_bicubic$rgb_psnr$bootstrap$low)),
  macro("GapRecordedUpper", fmt(strata$paired_delta_dit_minus_bicubic$rgb_psnr$bootstrap$high)),
  macro("GapBest", signed(max(crops$d_bicubic))),
  macro("GapWorst", signed(min(crops$d_bicubic))),
  macro("WinsBicubic", wins_bicubic$wins),
  macro("LossesBicubic", wins_bicubic$losses),
  macro("WinsNearest", wins_nearest$wins),
  macro("LossesNearest", wins_nearest$losses),
  macro("GapSignP", sci(gap_sign$p)),
  macro("GapWilcoxP", sci(gap_wilcox)),
  macro("GapTLower", fmt(gap_t$lower)),
  macro("GapTUpper", fmt(gap_t$upper)),
  macro("GapNearestSignP", sci(gap_nearest_sign$p)),

  macro("NoiseMax", fmt(noise$max_abs, 3)),
  macro("NoiseMean", fmt(noise$mean_abs, 3)),
  macro("NoiseShift", signed(noise$mean_shift, 4)),
  macro("BicubicRecordState", if (BICUBIC_IS_COPY) "the same bytes at two paths" else "two distinct records"),

  macro("CensusTotal", census$n_total),
  macro("CensusRan", census$n_run),
  macro("CensusSkipped", census$n_skipped_oom),
  macro("CensusSkipShare", fmt(100 * CENSUS_SKIP_SHARE, 1)),
  macro("CensusCameras", SKIPPED_CAMERAS),
  macro("AbsentGroups", sum(skipped_frame$measured == "no")),
  macro("BudgetPixels", thousands(census$vram_budget$max_upscaled_pixels)),
  macro("BudgetLong", census$vram_budget$max_upscaled_long),
  macro("BudgetVram", fmt(census$vram_budget$vram_mib / 1024, 0)),
  macro("SkippedSide", sizes$bins$upscaled_hw[[2]][1]),
  macro("SkippedPixels", thousands(SKIPPED_PIXELS)),
  macro("BudgetExcess", fmt(BUDGET_EXCESS, 1)),
  macro("OrphanStems", nrow(orphans$stems)),
  macro("CensusPathState",
        if (CENSUS_MATCHES_LIVE_PATH) "still matches the path it names"
        else "no longer matches the path it names"),

  macro("EvalRun", eval_now$n_run),
  macro("EvalSkipped", eval_now$n_skipped_oom),
  macro("EvalReferences", eval_now$gt$n_gt_matched),
  macro("PrimaryTier", tier_primary$status),
  macro("SotaTier", tier_sota$status),

  # The perceptual pass on the same crops, and the fidelity anchor that lets it
  # be read alongside the bound ranking.
  macro("LpipsWins", lp$dit_wins),
  macro("LpipsLosses", lp$bicubic_wins),
  macro("LpipsTies", lp$ties),
  macro("LpipsSignP", sci(lp$sign_test$p_two_sided)),
  macro("LpipsDit", fmt(lp$dit_mean, 3)),
  macro("LpipsBicubic", fmt(lp$bicubic_mean, 3)),
  macro("LpipsDelta", fmt(lp$mean_delta, 3)),
  macro("LpipsDeltaLo", fmt(lpips_ci[1], 3)),
  macro("LpipsDeltaHi", fmt(lpips_ci[2], 3)),
  macro("LpipsCanonWins", lp$camera_strata$Canon$dit_wins),
  macro("LpipsNikonWins", lp$camera_strata$Nikon$dit_wins),
  macro("QuadLossWin", quad$loss_win),
  macro("QuadLossLoss", quad$loss_loss),
  macro("QuadWinWin", quad$win_win),
  macro("QuadWinLoss", quad$win_loss),
  macro("AnchorDeltaDb", fmt(abs(ANCHOR_DELTA), 2)),
  macro("AnchorLocalPsnr", fmt(anchor$local_rgb_psnr_mean)),
  macro("AnchorLosses", anchor$local_losses_vs_bicubic_rgb_psnr),
  macro("PsnrLossesLocal", anchor$local_losses_vs_bicubic_rgb_psnr),
  macro("PsnrWinsLocal", anchor$local_wins_vs_bicubic_rgb_psnr),
  macro("GapBicubicLocal", signed(anchor$local_mean_delta_vs_bicubic_rgb_psnr)),
  macro("LpipsSeed", format(LPIPS_SEED, scientific = FALSE)),
  macro("LpipsSteps", perc_prov$dit4sr_seed20260909$inference$num_inference_steps),

  # VGG16 backbone-sensitivity secondary. Never used to rewrite the Alex thesis.
  macro("LpipsVggDit", fmt(vgg_lp$dit_mean, 3)),
  macro("LpipsVggBicubic", fmt(vgg_lp$bicubic_mean, 3)),
  macro("LpipsVggDelta", signed(vgg_lp$mean_delta, 3)),
  macro("LpipsVggDeltaLo", fmt(vgg_ci[1], 3)),
  macro("LpipsVggDeltaHi", fmt(vgg_ci[2], 3)),
  macro("LpipsVggWins", vgg_lp$dit_wins),
  macro("LpipsVggLosses", vgg_lp$bicubic_wins),
  macro("LpipsVggTies", vgg_lp$ties),
  macro("LpipsVggSignP", formatC(vgg_lp$sign_test$p_two_sided, format = "f", digits = 4)),
  macro("LpipsVggCanonWins", vgg_lp$camera_strata$Canon$dit_wins),
  macro("LpipsVggNikonWins", vgg_lp$camera_strata$Nikon$dit_wins),
  macro("QuadVggLossWin", vgg_quad$loss_win),
  macro("QuadVggLossLoss", vgg_quad$loss_loss),
  macro("QuadVggWinWin", vgg_quad$win_win),
  macro("QuadVggWinLoss", vgg_quad$win_loss),

  # The initialisation ablation on the toy transformer.
  macro("InitCells", nrow(init_cells)),
  macro("InitSeeds", length(unique(init_cells$seed))),
  macro("InitSteps", init_predecl$design$training$steps),
  macro("InitThreshold", fmt(INIT_THRESHOLD, 2)),
  macro("InitDefaultStall", stalls_by_mode[["library_default"]]),
  macro("InitStandardStall", stalls_by_mode[["dit_standard"]]),
  macro("InitZeroEscape", seeds_by_mode[["dit_zero"]] - stalls_by_mode[["dit_zero"]]),
  macro("InitZeroLoss", fmt(init_mode_loss[["dit_zero"]], 2)),
  macro("InitDefaultLoss", fmt(init_mode_loss[["library_default"]], 2)),
  macro("InitStandardLoss", fmt(init_mode_loss[["dit_standard"]], 2)),
  macro("InitStallLoss", fmt(mean(stalled_cells$mean_last10_loss), 2)),
  macro("InitZeroPsnr", fmt(init_mode_psnr[["dit_zero"]], 1)),
  macro("InitStallPsnr", fmt(mean(stalled_cells$restored_psnr_mean), 1)),
  macro("InitZeroGain", fmt(init_mode_psnr[["dit_zero"]] - mean(stalled_cells$restored_psnr_mean), 1)),
  macro("IdentityPsnr", fmt(IDENTITY_PSNR)),

  # Labelled published-table alignment and census-versus-crop128 leftover.
  # Secondary / sensitivity only; not a ranking of other methods.
  macro("PublishedDitPsnr", fmt(pub$alignment_bound$published_dit_psnr, 3)),
  macro("PublishedAlignDelta", fmt(pub$alignment_bound$abs_delta_y_db, 3)),
  macro("PublishedAlignLocalDelta", fmt(pub$alignment_local_sample$abs_delta_y_db, 3)),
  macro("PublishedStableSR", fmt(pub$collision$published_stablesr_psnr, 3)),
  macro("PublishedCollisionDelta", fmt(pub$collision$abs_delta_db, 3)),
  macro("PublishedDitSsim", fmt(pub$alignment_bound$published_dit_ssim, 3)),
  macro("PublishedSsimDelta", fmt(abs(pub$alignment_bound$delta_ssim), 3)),
  macro("CensusNameOverlap", leftover$stem_name_intersection_with_skip),
  macro("CensusNameOverlapRan", leftover$stem_name_intersection_with_ran),

  macro("NEvidence", nrow(manifest$entries)),
  macro("EvidenceBytes", format(sum(manifest$entries$bytes), big.mark = ","))
), "generated_numbers.tex")

write_generated(c(
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Arm & Parameters & Steps & Wall clock (s) & Final loss & PSNR (dB) \\\\",
  "\\midrule",
  paste0(toy_rows$arm, " & ",
         ifelse(is.na(toy_rows$params), "---", thousands(toy_rows$params)), " & ",
         ifelse(is.na(toy_rows$steps), "---", thousands(toy_rows$steps)), " & ",
         ifelse(is.na(toy_rows$seconds), "---", fmt(toy_rows$seconds)), " & ",
         ifelse(is.na(toy_rows$final_loss), "---", fmt(toy_rows$final_loss, 4)), " & ",
         fmt(toy_rows$psnr), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_toy.tex")

subset_rows <- data.frame(
  label = c("Nearest-neighbour upsampling", "Bicubic upsampling", "Published restoration method"),
  psnr = c(mean(crops$nearest_psnr), mean(crops$bicubic_psnr), mean(crops$dit_psnr)),
  ssim = c(mean(crops$nearest_ssim), mean(crops$bicubic_ssim), mean(crops$dit_ssim)),
  ypsnr = c(mean(crops$nearest_ypsnr), mean(crops$bicubic_ypsnr), mean(crops$dit_ypsnr)),
  yssim = c(mean(crops$nearest_yssim), mean(crops$bicubic_yssim), mean(crops$dit_yssim)),
  stringsAsFactors = FALSE
)

write_generated(c(
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Arm & PSNR (dB) & SSIM & Luma PSNR (dB) & Luma SSIM \\\\",
  "\\midrule",
  paste0(subset_rows$label, " & ", fmt(subset_rows$psnr), " & ", fmt(subset_rows$ssim, 3),
         " & ", fmt(subset_rows$ypsnr), " & ", fmt(subset_rows$yssim, 3), " \\\\"),
  "\\midrule",
  paste0("Method minus bicubic, paired & ", signed(mean(crops$d_bicubic)), " & ",
         signed(mean(crops$dit_ssim - crops$bicubic_ssim), 3), " & ",
         signed(mean(crops$dit_ypsnr - crops$bicubic_ypsnr)), " & ",
         signed(mean(crops$dit_yssim - crops$bicubic_yssim), 3), " \\\\"),
  paste0("Method minus nearest, paired & ", signed(mean(crops$d_nearest)), " & ",
         signed(mean(crops$dit_ssim - crops$nearest_ssim), 3), " & ",
         signed(mean(crops$dit_ypsnr - crops$nearest_ypsnr)), " & ",
         signed(mean(crops$dit_yssim - crops$nearest_yssim), 3), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_subset.tex")

write_generated(c(
  "\\begin{tabular}{lrl}",
  "\\toprule",
  "Source group & Inputs dropped & Present in the measured subset \\\\",
  "\\midrule",
  paste0(skipped_frame$camera, " & ", skipped_frame$n, " & ", skipped_frame$measured, " \\\\"),
  "\\midrule",
  paste0("All groups & ", sum(skipped_frame$n), " & --- \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_census.tex")

## The manifest itself, so the evidence discipline can be checked rather than believed.


message("wrote 11 figures to figs/out and 5 generated tex files to tex/")
unlink(file.path("tex", "generated_table_evidence.tex"), force = TRUE)
