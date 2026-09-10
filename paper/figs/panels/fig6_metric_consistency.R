# Figure 6. The model--bicubic gap on four recorded distortion metrics. PSNR
# and SSIM stay on separate native axes because a decibel difference and a
# unitless similarity difference are not directly comparable.

metric_effects$mean_label <- typeset_minus(ifelse(
  grepl("SSIM", as.character(metric_effects$unit)),
  sprintf("%+.3f", metric_effects$mean_delta),
  sprintf("%+.2f", metric_effects$mean_delta)
))
levels(metric_effects$metric) <- c(Y = "Luma (Y)", RGB = "RGB")[levels(metric_effects$metric)]

p <- ggplot(metric_effects, aes(x = mean_delta, y = metric)) +
  geom_vline(xintercept = 0, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.16, linewidth = 0.45) +
  geom_point(size = 2.3) +
  geom_text(aes(label = mean_label), vjust = -1.0, size = FIGURE_VALUE_LABEL_SIZE) +
  facet_wrap(~unit, scales = "free_x", ncol = 2) +
  scale_x_continuous(expand = expansion(mult = c(0.18, 0.22))) +
  scale_y_discrete(expand = expansion(add = 0.6)) +
  labs(x = "Paired mean difference, DiT \u2212 bicubic (native scale of each facet)", y = NULL,
       subtitle = sprintf("%d crop128 pairs; whiskers are 95%% percentile bootstrap intervals; vertical rule = equality",
                          SUBSET_N)) +
  rtx_theme() +
  theme(legend.position = "none", panel.spacing = unit(13, "pt"))

save_fig(p, "fig6_metric_consistency", width = FIGURE_TEXT_WIDTH_IN, height = 2.2)
