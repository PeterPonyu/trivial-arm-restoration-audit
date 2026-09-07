# Figure 6. The model--bicubic gap on four recorded distortion metrics. PSNR
# and SSIM stay on separate native axes because a decibel difference and a
# unitless similarity difference are not directly comparable.

metric_effects$mean_label <- ifelse(
  grepl("SSIM", as.character(metric_effects$unit)),
  sprintf("%+.3f", metric_effects$mean_delta),
  sprintf("%+.2f", metric_effects$mean_delta)
)

p <- ggplot(metric_effects, aes(x = mean_delta, y = metric)) +
  geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey25") +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.16, linewidth = 0.45) +
  geom_point(size = 2.5) +
  geom_text(aes(label = mean_label), vjust = -1.0, size = 2.5) +
  facet_wrap(~unit, scales = "free_x", ncol = 2) +
  scale_x_continuous(expand = expansion(mult = c(0.18, 0.22))) +
  labs(x = "Paired mean difference (DiT − bicubic)", y = NULL,
       subtitle = sprintf("%d crop128 pairs; whiskers = 95%% percentile bootstrap intervals",
                          SUBSET_N)) +
  rtx_theme() +
  theme(
    legend.position = "none",
    strip.text = element_text(size = 8.2),
    axis.text.y = element_text(size = 8.1),
    plot.subtitle = element_text(size = 7.6, colour = "grey25"),
    panel.spacing = unit(13, "pt")
  )

save_fig(p, "fig6_metric_consistency", width = FIGURE_TEXT_WIDTH_IN, height = 2.65)
