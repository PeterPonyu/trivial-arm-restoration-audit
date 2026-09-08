# Figure 0 -- the three scales at which the trivial arm decided the comparison.
#
# The numbers are the same toy, budget and crop-128 quantities the later
# figures already print. This page does not add a perceptual endpoint, an
# official ground-truth score, or an unrun initialisation arm.

if (nrow(toy_rows) < 4L) {
  stop("overview schematic needs the degraded, convolutional, longer and transformer rows")
}
if (!exists("SUBSET_N") || length(SUBSET_N) != 1L) {
  stop("overview schematic needs the measured crop count")
}

losses_bicubic <- sum(crops$dit_psnr < crops$bicubic_psnr)
gap_bicubic <- mean(crops$dit_psnr - crops$bicubic_psnr)

boxes <- data.frame(
  id = c("toy", "budget", "subset"),
  xmin = c(0.03, 0.345, 0.66),
  xmax = c(0.325, 0.64, 0.97),
  ymin = 0.26,
  ymax = 0.84,
  fill = c("#E8F1F8", "#EAF4E6", "#F8E8E8"),
  border = c("#4D7EA8", "#4D9221", "#B2182B"),
  stringsAsFactors = FALSE
)
boxes$xmid <- (boxes$xmin + boxes$xmax) / 2

# Centre the text on the box rather than on the canvas: an off-centre block
# reads as a box that was sized for something longer.
box_text <- data.frame(
  x = boxes$xmid,
  y = (boxes$ymin + boxes$ymax) / 2,
  label = c(
    paste0(
      "TOY SCALE\n",
      "Degraded input ", fmt(toy_rows$psnr[1]), " dB.\n",
      "Best trained arm ", fmt(toy_rows$psnr[2]), " dB.\n",
      "Both architectures sit\n",
      "below doing nothing."
    ),
    paste0(
      "LONGER BUDGET\n",
      "Objective falls; fidelity\n",
      "falls with it to ", fmt(toy_rows$psnr[3]), " dB.\n",
      "The untouched input is\n",
      "still the higher number."
    ),
    paste0(
      "CROP-128 SUBSET\n",
      losses_bicubic, " of ", SUBSET_N, " crops below\n",
      "bicubic on PSNR.\n",
      "Paired mean gap ",
      sprintf("%+.2f", gap_bicubic), " dB."
    )
  ),
  stringsAsFactors = FALSE
)

fig0 <- ggplot() +
  geom_rect(data = boxes, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = boxes$fill, colour = boxes$border, linewidth = 0.65) +
  geom_text(data = box_text, aes(x = x, y = y, label = label),
            family = FIGURE_FONT_FAMILY, size = 3.05, lineheight = 1.02,
            colour = "#202020") +
  annotate(
    "text", x = 0.5, y = 0.93,
    label = "Three scales, one deciding arm",
    family = FIGURE_FONT_FAMILY, size = 3.4, fontface = "bold", colour = "#202020"
  ) +
  annotate(
    "label", x = 0.5, y = 0.12,
    label = "The trivial arm is printed at every scale",
    family = FIGURE_FONT_FAMILY, size = 3.0, fontface = "bold",
    colour = "#4A4A4A", fill = "#F4F4F4",
    label.padding = grid::unit(0.18, "lines")
  ) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE, clip = "off") +
  labs(subtitle = "Each panel restates a quantity the later figures already draw from the same bound records") +
  theme_void() +
  theme(
    text = element_text(family = FIGURE_FONT_FAMILY),
    plot.subtitle = element_text(family = FIGURE_FONT_FAMILY, size = 8.0,
                                 colour = "#555555", hjust = 0.5,
                                 margin = margin(b = 5)),
    plot.margin = margin(t = 8, r = 8, b = 12, l = 8)
  )

save_fig(fig0, "fig0_three_scales", FIGURE_TEXT_WIDTH_IN, 2.85)
