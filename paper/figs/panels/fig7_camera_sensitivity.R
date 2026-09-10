# Figure 7. Camera-stratified paired sensitivity.
#
# The rows are the two camera strata already bound in E-STRATA.  The interval
# is the recorded within-stratum bootstrap over paired crop differences; this
# panel is descriptive and does not turn camera strata into scene clusters.

if (!exists("by_camera")) stop("camera-stratified summary was not loaded")

camera_plot <- by_camera
camera_plot <- camera_plot[order(camera_plot$camera), , drop = FALSE]
camera_plot$camera <- factor(camera_plot$camera, levels = unique(camera_plot$camera))
camera_plot$y <- seq_len(nrow(camera_plot))

# Two rows on a continuous axis need explicit room above and below them;
# without it the rows sit on the panel border with the whole middle empty.
p <- ggplot(camera_plot, aes(x = mean_delta, y = y)) +
  geom_vline(xintercept = 0, colour = FIGURE_RULE_COLOUR, linewidth = FIGURE_RULE_WIDTH) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.14, linewidth = 0.45) +
  geom_point(size = 2.2) +
  geom_text(aes(x = upper, label = sprintf("DiT wins %d of %d", wins, n)),
            hjust = -0.12, size = FIGURE_VALUE_LABEL_SIZE, family = FIGURE_FONT_FAMILY) +
  geom_text(aes(label = typeset_minus(sprintf("%+.2f", mean_delta))), vjust = -1.1,
            size = FIGURE_VALUE_LABEL_SIZE, family = FIGURE_FONT_FAMILY) +
  scale_x_continuous(name = "DiT \u2212 bicubic, RGB PSNR (dB)",
                     expand = expansion(mult = c(0.08, 0.22))) +
  scale_y_continuous(name = NULL, breaks = camera_plot$y, labels = levels(camera_plot$camera),
                     limits = c(0.4, nrow(camera_plot) + 0.6), expand = c(0, 0)) +
  labs(y = NULL,
       subtitle = "Recorded camera strata; whiskers are descriptive 95% percentile bootstrap intervals within each stratum") +
  rtx_theme()

save_fig(p, "fig7_camera_sensitivity", FIGURE_TEXT_WIDTH_IN, 1.9)
