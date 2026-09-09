# Figure 9 -- crop-level fidelity, camera intervals and the earlier census.
# All rows come from the bound crop128 metric pass. The census is a separate
# bound attempt and is shown as a scope inset; neither panel makes a perceptual
# claim or promotes the subset to the official 206-image table.

if (!exists("crops") || !exists("census") || !exists("eval_then")) {
  stop("crop and census evidence must be loaded before fig9")
}

metric_rows <- rbind(
  data.frame(stem = crops$stem, camera = crops$camera,
             metric = "RGB PSNR (dB)", difference = crops$d_bicubic),
  data.frame(stem = crops$stem, camera = crops$camera,
             metric = "RGB SSIM", difference = crops$dit_ssim - crops$bicubic_ssim)
)
metric_rows$metric <- factor(metric_rows$metric, levels = c("RGB PSNR (dB)", "RGB SSIM"))
metric_rows$rank <- ave(metric_rows$difference, metric_rows$metric,
                        FUN = function(x) rank(x, ties.method = "first"))

camera_metrics <- do.call(rbind, lapply(levels(metric_rows$metric), function(metric_name) {
  do.call(rbind, lapply(sort(unique(crops$camera)), function(camera_name) {
    d <- metric_rows$difference[metric_rows$metric == metric_name & metric_rows$camera == camera_name]
    ci <- bootstrap_mean(d)
    data.frame(metric = metric_name, camera = camera_name, n = length(d),
               mean_delta = mean(d), lower = ci[1], upper = ci[2], stringsAsFactors = FALSE)
  }))
}))
camera_metrics$metric <- factor(camera_metrics$metric, levels = levels(metric_rows$metric))

per_crop <- ggplot(metric_rows, aes(x = rank, y = difference, colour = camera)) +
  geom_hline(yintercept = 0, linewidth = 0.35, colour = "grey30") +
  geom_point(size = 0.9, alpha = 0.7) +
  facet_wrap(~metric, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = c("Canon" = "#4D7EA8", "Nikon" = "#B2182B"), name = "Camera") +
  scale_x_continuous(name = "Crops ordered within metric", breaks = c(1, 50, 100)) +
  scale_y_continuous(name = "DiT minus bicubic", expand = expansion(mult = 0.08)) +
  labs(subtitle = sprintf("n = %d crop pairs; negative values favour bicubic", nrow(crops))) +
  rtx_theme() + theme(legend.position = "bottom", plot.subtitle = element_text(size = 7.2, colour = "grey25"),
                      strip.text = element_text(size = 8))

intervals <- ggplot(camera_metrics, aes(x = mean_delta, y = camera)) +
  geom_vline(xintercept = 0, linewidth = 0.35, colour = "grey30") +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.12, linewidth = 0.5) +
  geom_point(size = 1.8) +
  facet_wrap(~metric, ncol = 1, scales = "free_x") +
  labs(x = "Mean paired difference", y = NULL, subtitle = "95% bootstrap intervals; Canon/Nikon strata") +
  rtx_theme() + theme(plot.subtitle = element_text(size = 7.2, colour = "grey25"),
                      axis.text.y = element_text(size = 7.2), strip.text = element_text(size = 8))

census_rows <- data.frame(
  attempt = factor(c("Earlier full\ncensus", "Earlier full\ncensus", "Scored crop128\nsubset"),
                   levels = c("Earlier full\ncensus", "Scored crop128\nsubset")),
  outcome = factor(c("Ran", "Skipped (OOM)", "Scored with GT"),
                   levels = c("Ran", "Skipped (OOM)", "Scored with GT")),
  n = c(as.integer(census$n_run), as.integer(census$n_skipped_oom), nrow(crops))
)
census_plot <- ggplot(census_rows, aes(x = attempt, y = n, fill = outcome)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = n), position = position_stack(vjust = 0.5), size = 2.5,
            colour = "white", family = FIGURE_FONT_FAMILY) +
  scale_fill_manual(values = c("Ran" = "#7A9E7E", "Skipped (OOM)" = "#B2182B", "Scored with GT" = "#4D7EA8"), name = NULL) +
  guides(fill = guide_legend(nrow = 2)) +
  labs(x = NULL, y = "Inputs", subtitle = sprintf("Scope census: %d → %d ran / %d skipped; scored subset n = %d",
                                                     census$n_total, census$n_run, census$n_skipped_oom, nrow(crops))) +
  rtx_theme() + theme(legend.position = "bottom", legend.text = element_text(size = 6.7),
                      plot.subtitle = element_text(size = 6.9, colour = "grey25"),
                      axis.text.x = element_text(size = 6.8))

p <- patchwork::wrap_plots(panel_label(per_crop, "A"), panel_label(intervals, "B"),
                           panel_label(census_plot, "C"), widths = c(1.55, 1, 0.90))
save_fig(p, "fig9_crop_camera_metrics", FIGURE_TEXT_WIDTH_IN, 3.60)
