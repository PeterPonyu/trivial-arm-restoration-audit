# Figure 1. The toy scale, with the arm that does nothing drawn as a line rather
# than left out. Every trained arm sits below it, which is the whole panel.
#
# Arms are placed on a numeric axis and relabelled, so the reference caption can
# be positioned between rows instead of on top of one.

toy_plot <- toy_rows[toy_rows$kind == "trained", ]
toy_plot$pos <- rev(seq_len(nrow(toy_plot)))

p <- ggplot(toy_plot, aes(x = pos, y = psnr)) +
  geom_hline(yintercept = TOY_REFERENCE, linewidth = 0.5, colour = "grey25") +
  annotate("text", x = 0.58, y = TOY_REFERENCE - 0.35, vjust = 0.35, hjust = 1, size = 2.7,
           colour = "grey25",
           label = sprintf("Degraded input, left alone: %.2f dB", TOY_REFERENCE)) +
  geom_segment(aes(xend = pos, y = 0, yend = psnr), linewidth = 0.4, colour = "grey55") +
  geom_point(size = 2.6, colour = "black") +
  geom_text(aes(label = sprintf("%.2f", psnr)), hjust = -0.45, size = 2.7) +
  scale_x_continuous(breaks = toy_plot$pos, labels = toy_plot$arm,
                     limits = c(0.4, nrow(toy_plot) + 0.6), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, TOY_REFERENCE * 1.3), expand = c(0, 0)) +
  coord_flip() +
  labs(x = NULL, y = "Restored fidelity against the reference image (dB)") +
  rtx_theme()

save_fig(p, "fig1_toy", width = 5.6, height = 2.2)
