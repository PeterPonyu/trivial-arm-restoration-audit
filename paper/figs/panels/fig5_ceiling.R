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

# Every segment carries its denominator.  The denominator is the number of
# inputs that attempt was given, not the number that eventually produced a
# metric; this keeps a memory drop and a missing reference visible rather than
# silently treating either as a zero-valued score.
attempt_totals <- c("Configured subset" = eval_now$n_run + eval_now$n_skipped_oom,
                    "Full input set" = census$n_total)
attempts$denom <- unname(attempt_totals[as.character(attempts$attempt)])
if (anyNA(attempts$denom) || any(tapply(attempts$n, attempts$attempt, sum) != attempt_totals)) {
  stop("ceiling panel does not account for every input in each attempt")
}
attempts$share <- attempts$n / attempts$denom
attempts$count_label <- sprintf("%d/%d\n(%.1f%%)", attempts$n, attempts$denom,
                                100 * attempts$share)

# A tiny first segment cannot hold a two-line label without touching the axis;
# move only those labels just beyond their segment while retaining the same
# stack coordinate.  Larger segments stay centred in their own area.
attempts$stack_start <- ave(attempts$n, attempts$attempt, FUN = function(x) cumsum(x) - x)
attempts$stack_center <- attempts$stack_start + attempts$n / 2
attempts$label_y <- ifelse(attempts$n > 0 & attempts$n < 10,
                           attempts$stack_start + attempts$n + 1.3,
                           attempts$stack_center)
attempts$label_hjust <- ifelse(attempts$n > 0 & attempts$n < 10, 0, 0.5)

attempt_totals_frame <- data.frame(
  attempt = factor(names(attempt_totals), levels = levels(attempts$attempt)),
  n = as.numeric(attempt_totals),
  label = sprintf("N = %d", as.numeric(attempt_totals)),
  stringsAsFactors = FALSE
)

survival <- ggplot(attempts, aes(x = attempt, y = n, fill = outcome)) +
  geom_col(width = 0.6, colour = "black", linewidth = 0.25) +
  geom_text(aes(y = label_y, label = ifelse(n > 0, count_label, ""),
                hjust = label_hjust),
            size = 2.20, colour = "black", lineheight = 0.90) +
  geom_text(data = attempt_totals_frame, aes(x = attempt, y = n, label = label),
            inherit.aes = FALSE, hjust = 0, vjust = 0.5, nudge_y = 14,
            size = 2.35,
            colour = "grey20") +
  scale_fill_manual(values = setNames(c("white", "grey80", "grey45"),
                                      c(DROPPED, UNSCORED, SCORED)),
                    name = NULL) +
  scale_y_continuous(limits = c(0, census$n_total * 1.35), expand = c(0, 0)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs the run was given") +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(8, "pt"), axis.text.y = element_text(size = 7),
        plot.subtitle = element_text(size = 7.1, colour = "grey25"))

dropped <- skipped_frame
dropped$camera <- factor(dropped$camera, levels = rev(dropped$camera))
dropped_total <- sum(dropped$n)
if (!identical(as.integer(dropped_total), as.integer(census$n_skipped_oom)) || dropped_total <= 0L) {
  stop("ceiling panel has no valid dropped-input denominator")
}
dropped$count_label <- sprintf("%d/%d (%.1f%%)", dropped$n, dropped_total,
                               100 * dropped$n / dropped_total)

composition <- ggplot(dropped, aes(x = camera, y = n, fill = measured)) +
  geom_col(width = 0.68, colour = "black", linewidth = 0.25) +
  geom_text(aes(label = count_label), hjust = -0.12, size = 2.20,
            lineheight = 0.90) +
  scale_fill_manual(values = c(no = "white", yes = "grey45"),
                    labels = c(no = "absent from the later subset",
                               yes = "present in the later subset"),
                    name = NULL) +
  scale_y_continuous(limits = c(0, max(dropped$n) * 1.48), expand = c(0, 0)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs dropped for memory") +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(8, "pt"), axis.text.y = element_text(size = 7),
        plot.subtitle = element_text(size = 7.1, colour = "grey25"))

p <- patchwork::wrap_plots(
  panel_label(survival, "A",
              subtitle = "n/N + %; N = inputs given"),
  panel_label(composition, "B",
              subtitle = sprintf("n/N + %%; N = %d dropped", dropped_total)),
                           widths = c(1.15, 1))

save_fig(p, "fig5_ceiling", width = FIGURE_TEXT_WIDTH_IN, height = 3.0)
