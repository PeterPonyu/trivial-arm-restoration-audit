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

p <- ggplot(camera_plot, aes(x = mean_delta, y = y)) +
  geom_vline(xintercept = 0, colour = "grey35", linewidth = 0.35) +
  geom_segment(aes(x = lower, xend = upper,
                   y = y, yend = y),
               colour = "#9C3D2E", linewidth = 0.8) +
  geom_point(shape = 21, size = 2.6, stroke = 0.7,
             colour = "#9C3D2E", fill = "white") +
  geom_text(aes(x = upper, label = sprintf("%d/%d wins", wins, n)),
            hjust = -0.08, size = 2.55, family = FIGURE_FONT_FAMILY) +
  scale_x_continuous(name = "DiT minus bicubic RGB PSNR (dB)",
                     expand = expansion(mult = c(0.08, 0.18))) +
  scale_y_continuous(name = NULL, breaks = camera_plot$y, labels = levels(camera_plot$camera)) +
  labs(y = NULL,
       subtitle = "Recorded camera strata; intervals are descriptive within-stratum bootstrap") +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        axis.text.y = element_text(size = FIGURE_AXIS_TEXT_SIZE))

save_fig(p, "fig7_camera_sensitivity", FIGURE_TEXT_WIDTH_IN, 2.55)
