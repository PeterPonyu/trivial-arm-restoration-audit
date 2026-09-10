# Figure 3. The subset scale, one point per crop. The diagonal is the boundary
# the published method would have to cross to beat an interpolation, and almost
# every crop sits on the same side of it.

lims <- range(c(crops$dit_psnr, crops$bicubic_psnr))
pad <- 0.04 * diff(lims)
axis_lim <- c(lims[1] - pad, lims[2] + pad)

p <- ggplot(crops, aes(x = bicubic_psnr, y = dit_psnr, shape = camera, colour = camera)) +
  geom_abline(slope = 1, intercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  annotate("text", x = axis_lim[2] - 0.3, y = axis_lim[2] - 0.3, label = "equality",
           hjust = 1, vjust = -0.6, angle = 45, size = FIGURE_ANNOTATION_SIZE,
           colour = FIGURE_RULE_COLOUR, family = FIGURE_FONT_FAMILY) +
  annotate("text", x = axis_lim[2] - 0.3, y = axis_lim[1] + 0.3,
           label = "below the diagonal:\nbicubic closer",
           hjust = 1, vjust = 0, size = FIGURE_ANNOTATION_SIZE, lineheight = 0.92,
           colour = "grey25", family = FIGURE_FONT_FAMILY) +
  geom_point(size = 1.6, alpha = 0.9, stroke = 0.5) +
  scale_shape_manual(values = FIGURE_CAMERA_SHAPES, name = "Camera group") +
  scale_colour_manual(values = FIGURE_CAMERA_COLOURS, name = "Camera group") +
  coord_fixed(xlim = axis_lim, ylim = axis_lim, expand = FALSE) +
  labs(x = "Bicubic upsampling, RGB PSNR (dB)", y = "Published method, RGB PSNR (dB)",
       subtitle = sprintf("%d of %d paired crops below equality; PSNR only",
                          wins_bicubic$losses, SUBSET_N)) +
  rtx_theme() +
  theme(legend.position = "inside",
        legend.position.inside = c(0.03, 0.97),
        legend.justification = c(0, 1),
        legend.background = element_rect(fill = "white", colour = NA))

save_fig(p, "fig3_subset", width = 0.62 * FIGURE_TEXT_WIDTH_IN, height = 3.9)
