# Figure 0 -- the three scales at which the trivial arm decided the comparison.
#
# The numbers are the same toy, budget and crop-128 quantities the later
# figures already print. This page does not add a perceptual endpoint, an
# official ground-truth score, or an unrun initialisation arm.
#
# The heading and the one-line gloss the panel used to carry restated the
# caption's first sentence; the caption keeps them and the panel does not, so
# the figure prints nothing twice.

if (nrow(toy_rows) < 4L) {
  stop("overview schematic needs the degraded, convolutional, longer and transformer rows")
}
if (!exists("SUBSET_N") || length(SUBSET_N) != 1L) {
  stop("overview schematic needs the measured crop count")
}

losses_bicubic <- sum(crops$dit_psnr < crops$bicubic_psnr)
gap_bicubic <- mean(crops$dit_psnr - crops$bicubic_psnr)

# Three cards, one per scale, in the shared palette: the same blue, orange and
# green that separate three arms elsewhere, so no card colour means "bad".
boxes <- data.frame(
  id = c("toy", "budget", "subset"),
  xmin = c(0.02, 0.345, 0.67),
  xmax = c(0.33, 0.655, 0.98),
  ymin = 0.30,
  ymax = 0.98,
  fill = c("#E6F0F7", "#FCF3E1", "#E3F4EE"),
  border = unname(FIGURE_PALETTE[c("blue", "orange", "green")]),
  stringsAsFactors = FALSE
)
boxes$xmid <- (boxes$xmin + boxes$xmax) / 2

heads <- data.frame(
  x = boxes$xmid, y = boxes$ymax - 0.10,
  label = c("Toy scale", "Longer budget", "Crop-128 subset"),
  stringsAsFactors = FALSE
)

# Centre the text on the box rather than on the canvas: an off-centre block
# reads as a box that was sized for something longer.
box_text <- data.frame(
  x = boxes$xmid,
  y = (boxes$ymin + boxes$ymax) / 2 - 0.06,
  label = c(
    paste0(
      "Degraded input ", fmt(toy_rows$psnr[1]), " dB.\n",
      "Best trained arm ", fmt(toy_rows$psnr[2]), " dB.\n",
      "Both architectures sit\n",
      "below doing nothing."
    ),
    paste0(
      "Objective falls; fidelity\n",
      "falls with it to ", fmt(toy_rows$psnr[3]), " dB.\n",
      "The untouched input is\n",
      "still the higher number."
    ),
    paste0(
      losses_bicubic, " of ", SUBSET_N, " crops below\n",
      "bicubic on PSNR.\n",
      "Paired mean gap ",
      typeset_minus(sprintf("%+.2f", gap_bicubic)), " dB."
    )
  ),
  stringsAsFactors = FALSE
)

# The connector under the three cards is the point of the page: one arm,
# printed at every scale.
BANNER_Y <- 0.11
connector <- data.frame(x = boxes$xmid, y = boxes$ymin, yend = BANNER_Y)

fig0 <- ggplot() +
  geom_rect(data = boxes, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = boxes$fill, colour = boxes$border, linewidth = 0.7) +
  geom_segment(data = connector, aes(x = x, xend = x, y = y, yend = yend),
               colour = "grey45", linewidth = 0.5) +
  annotate("segment", x = boxes$xmid[1], xend = boxes$xmid[3], y = BANNER_Y, yend = BANNER_Y,
           colour = "grey45", linewidth = 0.5) +
  geom_text(data = heads, aes(x = x, y = y, label = label),
            family = FIGURE_FONT_FAMILY, size = 3.2, fontface = "bold", colour = "#202020") +
  geom_text(data = box_text, aes(x = x, y = y, label = label),
            family = FIGURE_FONT_FAMILY, size = 2.9, lineheight = 1.05,
            colour = "#202020") +
  annotate(
    "label", x = 0.5, y = BANNER_Y,
    label = "The trivial arm \u2013 the input left alone, or bicubic \u2013 is printed at every scale",
    family = FIGURE_FONT_FAMILY, size = 2.9, fontface = "bold",
    colour = "#202020", fill = "white", linewidth = 0.3, label.r = grid::unit(0, "pt"),
    label.padding = grid::unit(0.22, "lines")
  ) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE, clip = "off") +
  theme_void() +
  theme(
    text = element_text(family = FIGURE_FONT_FAMILY),
    plot.margin = margin(t = 4, r = 4, b = 4, l = 4)
  )

save_fig(fig0, "fig0_three_scales", FIGURE_TEXT_WIDTH_IN, 2.0)
