# Figure 2. Ten times the training budget on the convolutional arm. The training
# objective improves and the fidelity of the output does not, so the two panels
# have to be read together; either alone would say the opposite thing.

budget <- toy_rows[toy_rows$arm %in% c("Convolutional arm, 50 steps",
                                       "Convolutional arm, 500 steps"), ]
budget$steps <- as.numeric(budget$steps)

LOSS_FACET <- "Training objective at the last step"
PSNR_FACET <- "Fidelity of the restored output, PSNR (dB)"

long <- rbind(
  data.frame(steps = budget$steps, value = budget$final_loss, facet = LOSS_FACET,
             label = sprintf("%.3f", budget$final_loss), stringsAsFactors = FALSE),
  data.frame(steps = budget$steps, value = budget$psnr, facet = PSNR_FACET,
             label = sprintf("%.2f", budget$psnr), stringsAsFactors = FALSE)
)
long$facet <- factor(long$facet, levels = c(LOSS_FACET, PSNR_FACET))

marks <- data.frame(facet = factor(PSNR_FACET, levels = levels(long$facet)),
                    y = TOY_REFERENCE)

p <- ggplot(long, aes(x = steps, y = value)) +
  geom_hline(data = marks, aes(yintercept = y), linewidth = FIGURE_RULE_WIDTH,
             colour = FIGURE_RULE_COLOUR) +
  geom_line(linewidth = 0.5, colour = "grey40") +
  geom_point(size = 2.3) +
  geom_text(aes(label = label), vjust = -1.15, size = FIGURE_VALUE_LABEL_SIZE) +
  geom_text(data = marks,
            aes(x = 275, y = y, label = sprintf("Degraded input, left alone: %.2f dB", y)),
            vjust = -0.55, size = FIGURE_ANNOTATION_SIZE, colour = FIGURE_RULE_COLOUR,
            inherit.aes = FALSE) +
  facet_wrap(~facet, scales = "free_y", ncol = 2) +
  scale_x_continuous(breaks = budget$steps, limits = c(-60, 610), expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0.14, 0.26))) +
  labs(x = "Training steps", y = NULL) +
  rtx_theme()

save_fig(p, "fig2_budget", width = FIGURE_TEXT_WIDTH_IN, height = 2.3)
