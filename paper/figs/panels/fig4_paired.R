# Figure 4. The paired differences, and the width the method varies by against
# itself. The shaded band in the left panel is the largest per-crop shift between
# two pixel sets of the same method: the gap has to be read against that width,
# not against zero alone. The right panel is the same differences averaged,
# overall and within each source group.

ordered <- crops[order(crops$d_bicubic), ]
ordered$rank <- seq_len(nrow(ordered))

spread <- ggplot(ordered, aes(x = rank, y = d_bicubic)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -noise$max_abs, ymax = noise$max_abs,
           fill = "grey65", alpha = 0.6) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey25") +
  geom_hline(yintercept = mean(crops$d_bicubic), linewidth = 0.4, linetype = "22") +
  geom_point(aes(shape = camera), size = 1.3, stroke = 0.4) +
  scale_shape_manual(values = c(1, 3), name = "Source group") +
  labs(x = "Crops, ordered by paired difference",
       y = "Published method minus bicubic (dB)",
       subtitle = sprintf("shaded band: %.3f dB, the method against itself",
                          noise$max_abs)) +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = 7, colour = "grey25"),
        legend.position = "bottom", legend.title = element_text(size = 7),
        legend.text = element_text(size = 7), legend.key.size = unit(8, "pt"))

means <- rbind(
  data.frame(camera = "All crops", n = nrow(crops), mean_delta = mean(crops$d_bicubic),
             lower = gap_ci[1], upper = gap_ci[2], stringsAsFactors = FALSE),
  by_camera[, c("camera", "n", "mean_delta", "lower", "upper")]
)
means$pos <- rev(seq_len(nrow(means)))

forest <- ggplot(means, aes(x = mean_delta, y = pos)) +
  geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey25") +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.12, linewidth = 0.4) +
  geom_point(size = 2.2) +
  geom_text(aes(label = sprintf("%+.2f", mean_delta)), vjust = -1.1, size = 2.6) +
  scale_y_continuous(breaks = means$pos,
                     labels = sprintf("%s\n(n = %d)", means$camera, means$n),
                     limits = c(0.5, nrow(means) + 0.5), expand = c(0, 0)) +
  scale_x_continuous(limits = c(min(means$lower) - 0.6, 0.6)) +
  labs(x = "Mean paired difference (dB)", y = NULL,
       subtitle = "bars: 95% bootstrap interval") +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = 7, colour = "grey25"),
        axis.text.y = element_text(size = 7))

p <- patchwork::wrap_plots(spread, forest, widths = c(1.35, 1))

save_fig(p, "fig4_paired", width = 6.0, height = 2.9)
