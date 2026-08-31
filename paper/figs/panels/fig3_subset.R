# Figure 3. The subset scale, one point per crop. The diagonal is the boundary
# the published method would have to cross to beat an interpolation, and almost
# every crop sits on the same side of it.

lims <- range(c(crops$dit_psnr, crops$bicubic_psnr))
pad <- 0.04 * diff(lims)

p <- ggplot(crops, aes(x = bicubic_psnr, y = dit_psnr, shape = camera)) +
  geom_abline(slope = 1, intercept = 0, linewidth = 0.5, colour = "grey25") +
  geom_point(size = 1.5, alpha = 0.85, stroke = 0.4) +
  scale_shape_manual(values = c(1, 3)) +
  coord_fixed(xlim = c(lims[1] - pad, lims[2] + pad),
              ylim = c(lims[1] - pad, lims[2] + pad)) +
  labs(x = "Bicubic upsampling (dB)", y = "Published method (dB)", shape = "Source group",
       subtitle = sprintf("%d of %d crops fall below the diagonal",
                          wins_bicubic$losses, SUBSET_N)) +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = 7.5, colour = "grey25")) +
  theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1),
        legend.background = element_blank(), legend.title = element_text(size = 7),
        legend.text = element_text(size = 7), legend.key.size = unit(9, "pt"))

save_fig(p, "fig3_subset", width = 0.62 * FIGURE_TEXT_WIDTH_IN, height = 3.6)
