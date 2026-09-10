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

# Segments are stacked in factor order from the axis outward
# (position_stack(reverse = TRUE)), and the label positions below are computed
# in that same order, so each label sits on the segment it counts.  A small
# segment cannot hold a two-line label without touching its neighbours; those
# labels are set just beyond the end of the bar instead, and a segment with no
# inputs prints nothing but stays in the legend.
attempts <- attempts[order(attempts$attempt, attempts$outcome), ]
attempts$stack_start <- ave(attempts$n, attempts$attempt, FUN = function(x) cumsum(x) - x)
attempts$stack_center <- attempts$stack_start + attempts$n / 2
small <- attempts$n > 0 & attempts$n < 30
attempts$label_y <- ifelse(small, attempts$stack_start + attempts$n + 3, attempts$stack_center)
attempts$label_hjust <- ifelse(small, 0, 0.5)
attempts$label_colour <- ifelse(attempts$outcome == SCORED & !small, "white", "black")

# Each attempt carries its denominator in its axis label, so no floating
# "N =" text has to compete with the segment labels for the same space.
attempt_axis_labels <- sprintf("%s\n(N = %d)", names(attempt_totals), as.integer(attempt_totals))
names(attempt_axis_labels) <- names(attempt_totals)

survival <- ggplot(attempts, aes(x = attempt, y = n, fill = outcome)) +
  geom_col(width = 0.6, colour = "black", linewidth = 0.25,
           position = position_stack(reverse = TRUE)) +
  geom_text(aes(y = label_y, label = ifelse(n > 0, count_label, ""),
                hjust = label_hjust, colour = label_colour),
            size = FIGURE_ANNOTATION_SIZE, lineheight = 0.90) +
  scale_colour_identity() +
  scale_fill_manual(values = setNames(unname(FIGURE_OUTCOME_FILLS[c("dropped", "unscored", "scored")]),
                                      c(DROPPED, UNSCORED, SCORED)),
                    name = NULL) +
  scale_x_discrete(labels = attempt_axis_labels) +
  scale_y_continuous(limits = c(0, census$n_total * 1.22), expand = c(0, 0)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs the run was given") +
  rtx_theme() +
  theme(legend.position = "bottom",
        axis.text.y = element_text(lineheight = 0.9))

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
  geom_text(aes(label = count_label), hjust = -0.12, size = FIGURE_ANNOTATION_SIZE,
            lineheight = 0.90) +
  scale_fill_manual(values = c(no = unname(FIGURE_OUTCOME_FILLS["dropped"]),
                               yes = unname(FIGURE_OUTCOME_FILLS["scored"])),
                    labels = c(no = "absent from the later crop128 protocol",
                               yes = "present in the later crop128 protocol"),
                    name = NULL) +
  scale_y_continuous(limits = c(0, max(dropped$n) * 1.85), expand = c(0, 0),
                     breaks = seq(0, 100, by = 20)) +
  coord_flip() +
  guides(fill = guide_legend(ncol = 1)) +
  labs(x = NULL, y = "Inputs dropped for memory") +
  rtx_theme() +
  theme(legend.position = "bottom")

p <- patchwork::wrap_plots(
  panel_label(survival, "A",
              subtitle = "Labels are n/N (%), N = inputs given"),
  panel_label(composition, "B",
              subtitle = sprintf("Labels are n/N (%%), N = %d dropped", dropped_total)),
                           widths = c(1.15, 1))

save_fig(p, "fig5_ceiling", width = FIGURE_TEXT_WIDTH_IN, height = 3.0)
