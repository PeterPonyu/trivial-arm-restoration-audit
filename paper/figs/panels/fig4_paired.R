# Figure 4. The paired differences, and the width the method varies by against
# itself. The shaded band in Panel A is the largest per-crop shift between
# two pixel sets of the same method: the gap has to be read against that width,
# not against zero alone. Panel B is the same differences averaged,
# overall and within each source group.

ordered <- crops[order(crops$d_bicubic), ]
ordered$rank <- seq_len(nrow(ordered))

# The re-run band is a few hundredths of a decibel on an axis spanning more
# than ten, so it is drawn in a saturated grey and named where it lies rather
# than left to be found.
band_label <- sprintf("re-run band \u00b1%.3f dB", noise$max_abs)
mean_label <- typeset_minus(sprintf("mean %+.2f dB", mean(crops$d_bicubic)))

spread <- ggplot(ordered, aes(x = rank, y = d_bicubic)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -noise$max_abs, ymax = noise$max_abs,
           fill = "grey45", alpha = 0.9) +
  geom_hline(yintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_hline(yintercept = mean(crops$d_bicubic), linewidth = FIGURE_RULE_WIDTH,
             linetype = FIGURE_THRESHOLD_LINETYPE, colour = FIGURE_RULE_COLOUR) +
  annotate("text", x = 1, y = noise$max_abs, label = band_label, hjust = 0, vjust = -0.5,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey25", family = FIGURE_FONT_FAMILY) +
  annotate("text", x = nrow(ordered), y = mean(crops$d_bicubic), label = mean_label,
           hjust = 1, vjust = 1.5, size = FIGURE_ANNOTATION_SIZE, colour = "grey25",
           family = FIGURE_FONT_FAMILY) +
  geom_point(aes(shape = camera, colour = camera), size = 1.4, stroke = 0.5) +
  scale_shape_manual(values = FIGURE_CAMERA_SHAPES, name = "Camera group") +
  scale_colour_manual(values = FIGURE_CAMERA_COLOURS, name = "Camera group") +
  scale_y_continuous(expand = expansion(mult = c(0.08, 0.14))) +
  labs(x = "Crops, ordered by paired difference",
       y = "Published method \u2212 bicubic (dB)",
       subtitle = sprintf("n = %d crops; solid rule = equality, dashed rule = mean", nrow(crops))) +
  rtx_theme() +
  theme(legend.position = "inside",
        legend.position.inside = c(0.03, 0.97),
        legend.justification = c(0, 1),
        legend.background = element_blank(),
        legend.direction = "horizontal")

means <- rbind(
  data.frame(camera = "All crops", n = nrow(crops), mean_delta = mean(crops$d_bicubic),
             lower = gap_ci[1], upper = gap_ci[2], stringsAsFactors = FALSE),
  by_camera[, c("camera", "n", "mean_delta", "lower", "upper")]
)
means$pos <- rev(seq_len(nrow(means)))

forest <- ggplot(means, aes(x = mean_delta, y = pos)) +
  geom_vline(xintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.12, linewidth = 0.45) +
  geom_point(size = 2.2) +
  geom_text(aes(label = typeset_minus(sprintf("%+.2f", mean_delta))), vjust = -1.1,
            size = FIGURE_VALUE_LABEL_SIZE) +
  scale_y_continuous(breaks = means$pos,
                     labels = sprintf("%s\n(n = %d)", means$camera, means$n),
                     limits = c(0.5, nrow(means) + 0.5), expand = c(0, 0)) +
  scale_x_continuous(limits = c(min(means$lower) - 0.6, 0.6)) +
  labs(x = "Mean paired difference (dB)", y = NULL,
       subtitle = "95% percentile bootstrap intervals over crops") +
  rtx_theme() +
  theme(axis.text.y = element_text(lineheight = 0.9))

p <- patchwork::wrap_plots(panel_label(spread, "A"), panel_label(forest, "B"),
                           widths = c(1.35, 1))

save_fig(p, "fig4_paired", width = FIGURE_TEXT_WIDTH_IN, height = 2.9)
