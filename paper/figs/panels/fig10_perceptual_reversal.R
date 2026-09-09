# Figure 10. The same crops on both axes of the perception--distortion plane.
# Horizontal: the released model minus bicubic on RGB PSNR for the fresh local
# sample (negative = bicubic closer to the reference). Vertical: bicubic minus
# the released model on the learned perceptual distance (positive = the model
# perceptually closer). The two zero rules cut the plane into quadrants; the
# count printed in each is recounted from the rows in make_figs.R.

if (!exists("perc_rows") || !exists("quad")) stop("perceptual rows were not loaded")

quad_labels <- data.frame(
  x = c(min(perc_rows$d_psnr_local), min(perc_rows$d_psnr_local),
        max(perc_rows$d_psnr_local), max(perc_rows$d_psnr_local)),
  y = c(max(perc_rows$d_lpips), min(perc_rows$d_lpips),
        max(perc_rows$d_lpips), min(perc_rows$d_lpips)),
  hjust = c(0, 0, 1, 1),
  vjust = c(1, 0, 1, 0),
  label = c(
    sprintf("PSNR loss, perceptual win: %d", quad$loss_win),
    sprintf("PSNR loss, perceptual loss: %d", quad$loss_loss),
    sprintf("PSNR win, perceptual win: %d", quad$win_win),
    sprintf("PSNR win, perceptual loss: %d", quad$win_loss)
  ),
  stringsAsFactors = FALSE
)

p <- ggplot(perc_rows, aes(x = d_psnr_local, y = d_lpips, shape = camera)) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey25") +
  geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey25") +
  geom_point(size = 1.5, alpha = 0.85, stroke = 0.4) +
  geom_text(data = quad_labels,
            aes(x = x, y = y, label = label, hjust = hjust, vjust = vjust),
            inherit.aes = FALSE, size = 2.5, colour = "grey20",
            family = FIGURE_FONT_FAMILY) +
  scale_shape_manual(values = c(16, 1), name = "Source group") +
  scale_x_continuous(expand = expansion(mult = 0.06)) +
  scale_y_continuous(expand = expansion(mult = 0.10)) +
  labs(x = "Released model minus bicubic, RGB PSNR (dB); negative = bicubic closer",
       y = "Bicubic minus released model, LPIPS; positive = model closer",
       subtitle = sprintf(
         "n = %d crops; model wins %d/%d on the perceptual distance and loses %d/%d on PSNR",
         nrow(perc_rows), lp$dit_wins, nrow(perc_rows),
         anchor$local_losses_vs_bicubic_rgb_psnr, nrow(perc_rows))) +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        legend.position = "bottom", legend.title = element_text(size = 7),
        legend.text = element_text(size = 7), legend.key.size = unit(8, "pt"))

save_fig(p, "fig10_perceptual_reversal", width = FIGURE_TEXT_WIDTH_IN, height = 3.4)
