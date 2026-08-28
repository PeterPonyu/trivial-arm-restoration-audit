# Assembling the arms of each comparison, and refusing to assemble one whose
# records disagree with each other.
#
# Nothing here estimates anything. It joins per-crop rows across arms on the
# crop name, checks that records written by different passes still describe the
# same run, and hands back frames the panels can draw.

# Per-crop rows join on the crop name rather than on position: the metric passes
# wrote their rows independently, and a silent reordering would otherwise pair
# the wrong crops.
join_crops <- function(...) {
  arms <- list(...)
  if (is.null(names(arms)) || any(names(arms) == "")) {
    stop("every arm must be passed with a name; unnamed arms cannot be labelled")
  }
  stems <- arms[[1]]$per_stem$stem
  out <- data.frame(stem = stems, stringsAsFactors = FALSE)
  for (label in names(arms)) {
    rows <- arms[[label]]$per_stem
    idx <- match(stems, rows$stem)
    if (anyNA(idx)) stop("arm '", label, "' does not cover the same crops as the first arm")
    out[[paste0(label, "_psnr")]] <- rows$rgb_psnr[idx]
    out[[paste0(label, "_ssim")]] <- rows$rgb_ssim[idx]
    out[[paste0(label, "_ypsnr")]] <- rows$y_psnr_shave4[idx]
    out[[paste0(label, "_yssim")]] <- rows$y_ssim_shave4[idx]
  }
  out
}

# Two records of the same arm must agree crop for crop. They may agree because
# one is a copy of the other; that is reported separately by comparing digests,
# and this check exists so that a divergence stops the build either way.
assert_arms_agree <- function(a, b, label, tol = 1e-12) {
  if (!identical(a$per_stem$stem, b$per_stem$stem)) {
    stop(label, ": the two records cover different crops")
  }
  for (column in c("rgb_psnr", "rgb_ssim", "y_psnr_shave4", "y_ssim_shave4")) {
    if (max(abs(a$per_stem[[column]] - b$per_stem[[column]])) > tol) {
      stop(label, ": the two records disagree on ", column)
    }
  }
  invisible(TRUE)
}

# The same method scored twice over the same crops from two pixel sets. This is
# not a check but a measurement: it is what the paper uses to say how much of any
# gap could be the method's own variability.
run_to_run <- function(a, b) {
  if (!identical(a$per_stem$stem, b$per_stem$stem)) {
    stop("the two pixel sets of the method do not cover the same crops")
  }
  delta <- b$per_stem$rgb_psnr - a$per_stem$rgb_psnr
  list(
    max_abs = max(abs(delta)),
    mean_abs = mean(abs(delta)),
    mean_shift = mean(b$per_stem$rgb_psnr) - mean(a$per_stem$rgb_psnr),
    n = length(delta)
  )
}

# Wins, losses and ties for one arm against another, overall or within a stratum.
# Recomputed from the per-crop rows so the recorded counts can be checked rather
# than quoted.
win_counts <- function(a, b) {
  delta <- a - b
  list(n = length(delta), wins = sum(delta > 0), losses = sum(delta < 0),
       ties = sum(delta == 0))
}

# The toy arms, read out of the one record that holds the two matched runs plus
# the degraded input they were all scored against, with the longer run of the
# convolutional arm appended from the record that was never promoted.
toy_arms <- function(toy, longer) {
  unet <- toy$metrics$`unet_result.json`
  dit <- toy$metrics$`dit_result.json`
  if (!isTRUE(all.equal(unet$eval$degraded_input_psnr_mean, dit$eval$degraded_input_psnr_mean))) {
    stop("the two toy arms were scored against different degraded inputs")
  }
  if (!identical(unet$eval$n_test_pairs, dit$eval$n_test_pairs)) {
    stop("the two toy arms were scored on different numbers of test pairs")
  }
  if (!identical(longer$eval$n_test_pairs, unet$eval$n_test_pairs)) {
    stop("the longer run was scored on a different number of test pairs")
  }
  if (!isTRUE(all.equal(longer$eval$degraded_input_psnr_mean,
                        unet$eval$degraded_input_psnr_mean))) {
    stop("the longer run was scored against a different degraded input")
  }
  data.frame(
    arm = c("Degraded input, left alone",
            "Convolutional arm, 50 steps",
            "Convolutional arm, 500 steps",
            "Transformer arm, 50 steps"),
    kind = c("reference", "trained", "trained", "trained"),
    psnr = c(unet$eval$degraded_input_psnr_mean,
             unet$eval$restored_psnr_mean,
             longer$eval$restored_psnr_mean,
             dit$eval$restored_psnr_mean),
    ssim = c(unet$eval$degraded_input_ssim_mean,
             unet$eval$restored_ssim_mean,
             longer$eval$restored_ssim_mean,
             dit$eval$restored_ssim_mean),
    params = c(NA_real_, unet$train$n_params, longer$train$n_params, dit$train$n_params),
    steps = c(NA_real_, unet$train$n_steps, longer$train$n_steps, dit$train$n_steps),
    seconds = c(NA_real_, unet$train$elapsed_sec, longer$train$elapsed_sec, dit$train$elapsed_sec),
    final_loss = c(NA_real_, unet$train$final_loss, longer$train$final_loss, dit$train$final_loss),
    last10_loss = c(NA_real_, unet$train$mean_last10_loss, longer$train$mean_last10_loss,
                    dit$train$mean_last10_loss),
    stringsAsFactors = FALSE
  )
}

# Short crop labels for axes. The tables print the recorded name, so the two
# never disagree about which crop is being named.
short_stem <- function(x) sub("_LR4$", "", x)

camera_of <- function(x) sub("_.*$", "", x)
