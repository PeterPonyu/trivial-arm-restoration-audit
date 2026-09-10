# Figure 10. The same crops on both axes of the perception--distortion plane.
# Horizontal: the released model minus bicubic on RGB PSNR for the fresh local
# sample (negative = bicubic closer to the reference). Vertical: bicubic minus
# the released model on the learned perceptual distance (positive = the model
# perceptually closer). The two zero rules cut the plane into quadrants; the
# count printed in each is recounted from the rows in make_figs.R.
#
# Both axis titles carry the direction of each axis in words and arrows, so the
# reader does not have to derive "which side is the model" from a sign
# convention. The quadrant in which the two endpoints disagree in the direction
# the trade-off predicts is shaded; it holds most of the crops and is the
# figure's point.

if (!exists("perc_rows") || !exists("quad")) stop("perceptual rows were not loaded")

x_range <- range(perc_rows$d_psnr_local)
y_range <- range(perc_rows$d_lpips)
x_pad <- 0.05 * diff(x_range)
y_pad <- 0.20 * diff(y_range)
x_lim <- c(x_range[1] - x_pad, x_range[2] + x_pad)
y_lim <- c(y_range[1] - y_pad, y_range[2] + y_pad)

# One label per quadrant, anchored to the panel corner nearest to it, with the
# bottom-left label pushed toward the vertical rule so it does not sit on the
# most extreme crop.  The count is the record's; the second line names the
# quadrant in words.
inset_x <- 0.012 * diff(x_lim)
inset_y <- 0.03 * diff(y_lim)
quad_labels <- data.frame(
  x = c(x_lim[1] + inset_x, -inset_x * 2, x_lim[2] - inset_x, x_lim[2] - inset_x),
  y = c(y_lim[2] - inset_y, y_lim[1] + inset_y, y_lim[2] - inset_y, y_lim[1] + inset_y),
  hjust = c(0, 1, 1, 1),
  vjust = c(1, 0, 1, 0),
  count = sprintf("%d crops", c(quad$loss_win, quad$loss_loss, quad$win_win, quad$win_loss)),
  what = c("bicubic closer on PSNR,\nmodel closer on LPIPS",
           "bicubic closer on both",
           "model closer on both",
           "model closer on PSNR,\nbicubic closer on LPIPS"),
  stringsAsFactors = FALSE
)
# The description sits under the count in the upper quadrants and above it in
# the lower ones; the offset is in data units so it is stable across rebuilds.
count_height <- 0.075 * diff(y_lim)
quad_labels$y_what <- ifelse(quad_labels$vjust == 1,
                             quad_labels$y - count_height,
                             quad_labels$y + count_height)

p <- ggplot(perc_rows, aes(x = d_psnr_local, y = d_lpips)) +
  annotate("rect", xmin = -Inf, xmax = 0, ymin = 0, ymax = Inf,
           fill = "grey93", colour = NA) +
  geom_hline(yintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_vline(xintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_point(aes(shape = camera, colour = camera), size = 1.7, alpha = 0.9, stroke = 0.55) +
  geom_text(data = quad_labels,
            aes(x = x, y = y, label = count, hjust = hjust, vjust = vjust),
            inherit.aes = FALSE, size = 3.2, fontface = "bold", colour = "grey15",
            family = FIGURE_FONT_FAMILY) +
  geom_text(data = quad_labels,
            aes(x = x, y = y_what, label = what, hjust = hjust, vjust = vjust),
            inherit.aes = FALSE, size = FIGURE_ANNOTATION_SIZE, colour = "grey25",
            lineheight = 0.92, family = FIGURE_FONT_FAMILY) +
  scale_shape_manual(values = FIGURE_CAMERA_SHAPES, name = "Camera group") +
  scale_colour_manual(values = FIGURE_CAMERA_COLOURS, name = "Camera group") +
  scale_x_continuous(limits = x_lim, expand = c(0, 0)) +
  scale_y_continuous(limits = y_lim, expand = c(0, 0), breaks = seq(-0.4, 0.6, by = 0.1)) +
  labs(x = "Released model \u2212 bicubic, RGB PSNR (dB)\n\u2190 bicubic closer to the reference   |   model closer to the reference \u2192",
       y = "Bicubic \u2212 released model, LPIPS (AlexNet)\n\u2190 bicubic closer   |   model closer \u2192",
       subtitle = sprintf(
         paste0("n = %d crops; bicubic is closer to the reference on PSNR on %d of them, ",
                "the model on LPIPS on %d\nshaded quadrant: the two endpoints rank the same crop in opposite orders"),
         nrow(perc_rows), anchor$local_losses_vs_bicubic_rgb_psnr, lp$dit_wins)) +
  rtx_theme() +
  theme(legend.position = "bottom",
        axis.title.x = element_text(lineheight = 1.05, margin = margin(t = 4)),
        axis.title.y = element_text(lineheight = 1.05, margin = margin(r = 4)),
        plot.margin = margin(t = 4, r = 6, b = 2, l = 4))

save_fig(p, "fig10_perceptual_reversal", width = FIGURE_TEXT_WIDTH_IN, height = 3.6)
