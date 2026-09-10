# Figure 1. The toy scale, with the arm that does nothing drawn as a line rather
# than left out. Every trained arm sits below it, which is the whole panel.
#
# Arms are placed on a numeric axis and relabelled, so the reference caption can
# be positioned between rows instead of on top of one.

toy_plot <- toy_rows[toy_rows$kind == "trained", ]
toy_plot$pos <- rev(seq_len(nrow(toy_plot)))

p <- ggplot(toy_plot, aes(x = pos, y = psnr)) +
  geom_hline(yintercept = TOY_REFERENCE, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  annotate("text", x = nrow(toy_plot) + 0.45, y = TOY_REFERENCE - 0.3, vjust = 1, hjust = 1,
           size = FIGURE_ANNOTATION_SIZE, colour = FIGURE_RULE_COLOUR,
           label = sprintf("Degraded input, left alone: %.2f dB", TOY_REFERENCE)) +
  geom_segment(aes(xend = pos, y = 0, yend = psnr), linewidth = 0.4, colour = "grey55") +
  geom_point(size = 2.6, colour = "black") +
  geom_text(aes(label = sprintf("%.2f", psnr)), hjust = -0.45, size = FIGURE_VALUE_LABEL_SIZE) +
  scale_x_continuous(breaks = toy_plot$pos, labels = toy_plot$arm,
                     limits = c(0.4, nrow(toy_plot) + 0.6), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, TOY_REFERENCE * 1.2), expand = c(0, 0),
                     breaks = seq(0, 25, by = 5)) +
  coord_flip() +
  labs(x = NULL, y = "Restored fidelity against the reference image, PSNR (dB)") +
  rtx_theme()

save_fig(p, "fig1_toy", width = FIGURE_TEXT_WIDTH_IN, height = 2.2)
