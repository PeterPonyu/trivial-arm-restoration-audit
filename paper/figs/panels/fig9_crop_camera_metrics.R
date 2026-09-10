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

per_crop <- ggplot(metric_rows, aes(x = rank, y = difference, colour = camera, shape = camera)) +
  geom_hline(yintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_point(size = 1.1, alpha = 0.85, stroke = 0.45) +
  facet_wrap(~metric, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = FIGURE_CAMERA_COLOURS, name = NULL) +
  scale_shape_manual(values = FIGURE_CAMERA_SHAPES, name = NULL) +
  scale_x_continuous(name = "Crops, ordered within each metric", breaks = c(1, 50, 100)) +
  scale_y_continuous(name = "DiT \u2212 bicubic", expand = expansion(mult = c(0.10, 0.22))) +
  labs(subtitle = sprintf("n = %d pairs; negative favours bicubic", nrow(crops))) +
  rtx_theme() +
  # The upper-left of the PSNR facet is empty (every crop there is negative),
  # so the camera key sits inside it rather than in a row of its own below.
  theme(legend.position = "inside",
        legend.position.inside = c(0.03, 0.99),
        legend.justification = c(0, 1),
        legend.direction = "horizontal",
        legend.background = element_blank())

intervals <- ggplot(camera_metrics, aes(x = mean_delta, y = camera)) +
  geom_vline(xintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.18, linewidth = 0.5) +
  geom_point(size = 2.0) +
  facet_wrap(~metric, ncol = 1, scales = "free_x") +
  scale_x_continuous(expand = expansion(mult = c(0.12, 0.12))) +
  scale_y_discrete(expand = expansion(add = 0.7)) +
  labs(x = "Mean paired difference", y = NULL,
       subtitle = "95% bootstrap intervals") +
  rtx_theme()

# The census and the scored protocol, drawn as horizontal bars so the two
# attempt names sit on the vertical axis and cannot collide.  The fills are the
# shared outcome greys: white for an input that produced nothing, light grey
# for one that ran without a reference, mid grey for a scored one.
SKIPPED <- "Skipped for memory"
RAN_UNSCORED <- "Ran, no reference"
SCORED_GT <- "Scored against a reference"
census_rows <- data.frame(
  attempt = factor(c("Earlier full\ncensus", "Earlier full\ncensus", "Scored crop128\nprotocol"),
                   levels = c("Scored crop128\nprotocol", "Earlier full\ncensus")),
  outcome = factor(c(SKIPPED, RAN_UNSCORED, SCORED_GT),
                   levels = c(SKIPPED, RAN_UNSCORED, SCORED_GT)),
  n = c(as.integer(census$n_skipped_oom), as.integer(census$n_run), nrow(crops)),
  stringsAsFactors = FALSE
)
census_fills <- setNames(unname(FIGURE_OUTCOME_FILLS[c("dropped", "unscored", "scored")]),
                         c(SKIPPED, RAN_UNSCORED, SCORED_GT))
# Each segment is labelled in words on or beside the bar, so the panel needs
# no legend and stands the same height as its neighbours.  The skipped count
# sits inside its wide segment; the thirteen unscored inputs are too narrow a
# segment for a label, so theirs sits above the bar end; the scored count sits
# beside its bar in the empty right half of that row.
census_text <- data.frame(
  x = c(2, 2.42, 1),
  y = c(census$n_skipped_oom / 2, census$n_total, nrow(crops) + 5),
  hjust = c(0.5, 1, 0),
  vjust = c(0.5, 0, 0.5),
  label = c(sprintf("%d skipped for memory", census$n_skipped_oom),
            sprintf("%d ran, no reference", census$n_run),
            sprintf("%d scored against\na reference", nrow(crops))),
  stringsAsFactors = FALSE
)

census_plot <- ggplot(census_rows, aes(x = attempt, y = n, fill = outcome)) +
  geom_col(width = 0.62, colour = "black", linewidth = 0.25,
           position = position_stack(reverse = TRUE)) +
  geom_text(data = census_text,
            aes(x = x, y = y, label = label, hjust = hjust, vjust = vjust),
            inherit.aes = FALSE, size = FIGURE_ANNOTATION_SIZE, lineheight = 0.9,
            family = FIGURE_FONT_FAMILY) +
  scale_fill_manual(values = census_fills, guide = "none") +
  scale_x_discrete(expand = expansion(add = c(0.55, 0.85))) +
  scale_y_continuous(limits = c(0, census$n_total * 1.22), expand = c(0, 0),
                     breaks = seq(0, 200, by = 50)) +
  coord_flip() +
  labs(x = NULL, y = "Inputs") +
  rtx_theme() +
  theme(axis.text.y = element_text(lineheight = 0.9))

p <- patchwork::wrap_plots(panel_label(per_crop, "A"), panel_label(intervals, "B"),
                           panel_label(census_plot, "C"), widths = c(1.55, 1, 1.05))
save_fig(p, "fig9_crop_camera_metrics", FIGURE_TEXT_WIDTH_IN, 3.00)
