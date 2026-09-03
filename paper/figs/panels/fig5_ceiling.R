# Figure 5. What the memory ceiling selected. Panel A is what became of
# every input each run was given; Panel B is which source groups the
# ceiling removed. The middle outcome in Panel A is the one that matters: an
# input can survive the ceiling and still not be scorable.

ORPHANS_SCORED <- sum(orphans$stems$metric != "not_computed")
ORPHANS_WITH_REFERENCE <- sum(!is.na(orphans$stems$gt_path))

DROPPED <- "Dropped for memory"
UNSCORED <- "Run, but no reference to score against"
SCORED <- "Run and scored"

attempts <- rbind(
  data.frame(attempt = "Full input set", outcome = DROPPED,
             n = census$n_skipped_oom, stringsAsFactors = FALSE),
  data.frame(attempt = "Full input set", outcome = UNSCORED,
             n = census$n_run - ORPHANS_WITH_REFERENCE, stringsAsFactors = FALSE),
  data.frame(attempt = "Full input set", outcome = SCORED,
             n = ORPHANS_SCORED, stringsAsFactors = FALSE),
  data.frame(attempt = "Configured subset", outcome = DROPPED,
             n = eval_now$n_skipped_oom, stringsAsFactors = FALSE),
  data.frame(attempt = "Configured subset", outcome = UNSCORED,
             n = eval_now$n_run - eval_now$gt$n_gt_matched, stringsAsFactors = FALSE),
  data.frame(attempt = "Configured subset", outcome = SCORED,
             n = eval_now$gt$n_gt_matched, stringsAsFactors = FALSE)
)
attempts$attempt <- factor(attempts$attempt, levels = c("Configured subset", "Full input set"))
attempts$outcome <- factor(attempts$outcome, levels = c(DROPPED, UNSCORED, SCORED))

survival <- ggplot(attempts, aes(x = attempt, y = n, fill = outcome)) +
  geom_col(width = 0.6, colour = "black", linewidth = 0.25) +
  scale_fill_manual(values = setNames(c("white", "grey80", "grey45"),
                                      c(DROPPED, UNSCORED, SCORED)),
                    name = NULL) +
  scale_y_continuous(limits = c(0, census$n_total * 1.04), expand = c(0, 0)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs the run was given") +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(8, "pt"), axis.text.y = element_text(size = 7))

dropped <- skipped_frame
dropped$camera <- factor(dropped$camera, levels = rev(dropped$camera))

composition <- ggplot(dropped, aes(x = camera, y = n, fill = measured)) +
  geom_col(width = 0.68, colour = "black", linewidth = 0.25) +
  geom_text(aes(label = n), hjust = -0.35, size = 2.5) +
  scale_fill_manual(values = c(no = "white", yes = "grey45"),
                    labels = c(no = "absent from the later subset",
                               yes = "present in the later subset"),
                    name = NULL) +
  scale_y_continuous(limits = c(0, max(dropped$n) * 1.24), expand = c(0, 0)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs dropped for memory") +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(8, "pt"), axis.text.y = element_text(size = 7))

p <- patchwork::wrap_plots(panel_label(survival, "A"), panel_label(composition, "B"),
                           widths = c(1.15, 1))

save_fig(p, "fig5_ceiling", width = FIGURE_TEXT_WIDTH_IN, height = 3.0)
