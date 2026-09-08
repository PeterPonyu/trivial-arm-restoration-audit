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
## Figures. Each panel reads the objects above and writes one file.
## ---------------------------------------------------------------------------

for (unit in c("fig0_three_scales.R", "fig1_toy.R", "fig2_budget.R",
               "fig3_subset.R", "fig4_paired.R", "fig5_ceiling.R",
               "fig6_metric_consistency.R", "fig7_camera_sensitivity.R")) {
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
  macro("NoiseMargin", fmt(NOISE_MARGIN, 0)),
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
  macro("PerceptualState", if (isTRUE(dit$lpips$computed)) "computed" else "not computed"),
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

write_generated(evidence_table(manifest), "generated_table_evidence.tex")

message("wrote 8 figures to figs/out and 5 generated tex files to tex/")
