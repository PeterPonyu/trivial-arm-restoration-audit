# Figure 11. The training objective under three initialisations, three seeds
# each, and where each cell finished against the arm that does nothing.
#
# Panel A: the record holds two summary points per cell -- the mean over the
# first ten steps and the mean over the last ten -- and the last step; the
# trajectory drawn is those points joined, not a per-step curve. The rule at
# unity is what a network contributing nothing produces; the dashed rule is the
# predeclared stall threshold. The axis is linear: the cells span roughly 0.4
# to 1.9, less than one decade, and the two rules that matter sit a tenth apart.
#
# Panel B: the restored fidelity of the same nine cells against the degraded
# input left alone, the toy reference the manuscript prints. Every cell is
# below it, which is the trivial arm's verdict on the ablation.
#
# Arms are told apart by colour (the same colour in both panels) and seeds by
# line type and symbol, so a black-and-white print still separates the seeds
# and the facet strips still separate the arms.

if (!exists("init_cells")) stop("initialisation cells were not loaded")

mode_labels <- c(library_default = "Library default\n(gates not zero)",
                 dit_standard = "Standard scheme\n(gates not zero)",
                 dit_zero = "Zero-gated scheme\n(gates exactly zero)")
mode_colours <- setNames(unname(FIGURE_INIT_COLOURS[names(mode_labels)]), mode_labels)

traj <- do.call(rbind, lapply(seq_len(nrow(init_cells)), function(i) {
  cell <- init_cells[i, ]
  data.frame(
    mode = cell$mode, seed = cell$seed,
    stage = c("First ten steps", "Last ten steps", "Final step"),
    order = c(1, 2, 3),
    loss = c(cell$mean_first10_loss, cell$mean_last10_loss, cell$final_loss),
    stringsAsFactors = FALSE
  )
}))
traj$mode <- factor(mode_labels[traj$mode], levels = mode_labels)
traj$seed <- factor(traj$seed)

seed_shapes <- c(21, 22, 24)
seed_linetypes <- c("solid", "42", "12")

# The two rules are named inside the arm that crosses them, where the region
# around them is empty; in the other two arms every point sits on the rule.
rule_labels <- data.frame(
  mode = factor(mode_labels[["dit_zero"]], levels = mode_labels),
  x = 3.2,
  y = c(1, INIT_THRESHOLD),
  vjust = c(-0.45, 1.35),
  label = c("unity", sprintf("threshold %.2f", INIT_THRESHOLD)),
  stringsAsFactors = FALSE
)

trajectories <- ggplot(traj, aes(x = order, y = loss, group = seed)) +
  geom_hline(yintercept = 1, linewidth = FIGURE_RULE_WIDTH, colour = FIGURE_RULE_COLOUR) +
  geom_hline(yintercept = INIT_THRESHOLD, linewidth = FIGURE_RULE_WIDTH,
             linetype = FIGURE_THRESHOLD_LINETYPE, colour = FIGURE_RULE_COLOUR) +
  geom_text(data = rule_labels, aes(x = x, y = y, label = label, vjust = vjust),
            inherit.aes = FALSE, hjust = 1, size = FIGURE_ANNOTATION_SIZE,
            colour = FIGURE_RULE_COLOUR, family = FIGURE_FONT_FAMILY) +
  geom_line(aes(linetype = seed, colour = mode), linewidth = 0.55) +
  geom_point(aes(shape = seed, colour = mode), size = 2.0, stroke = 0.6, fill = "white") +
  facet_wrap(~mode, nrow = 1) +
  scale_x_continuous(breaks = 1:3,
                     labels = c("First ten\nsteps", "Last ten\nsteps", "Final\nstep"),
                     expand = expansion(mult = 0.12)) +
  scale_y_continuous(expand = expansion(mult = c(0.10, 0.12))) +
  scale_shape_manual(values = seed_shapes, name = "Seed") +
  scale_linetype_manual(values = seed_linetypes, name = "Seed") +
  scale_colour_manual(values = mode_colours, guide = "none") +
  labs(x = NULL, y = "Training objective (mean squared error)",
       subtitle = sprintf("%d cells, %d steps each; one line per seed",
                          nrow(init_cells), init_predecl$design$training$steps)) +
  rtx_theme() +
  theme(legend.position = "bottom",
        axis.text.x = element_text(lineheight = 0.9),
        strip.text = element_text(lineheight = 0.95),
        panel.spacing.x = unit(8, "pt"))

fidelity <- init_cells[, c("mode", "seed", "restored_psnr_mean")]
fidelity$mode <- factor(mode_labels[fidelity$mode], levels = mode_labels)
fidelity$seed <- factor(fidelity$seed)
fidelity$mode_short <- factor(sub("\n.*$", "", as.character(fidelity$mode)),
                              levels = sub("\n.*$", "", mode_labels))
levels(fidelity$mode_short) <- c("Library\ndefault", "Standard\nscheme", "Zero-gated\nscheme")

# The discrete horizontal scale is declared before any layer so the numeric
# anchor of the reference label cannot make ggplot infer a continuous one.
restored <- ggplot(fidelity, aes(x = mode_short, y = restored_psnr_mean)) +
  scale_x_discrete(expand = expansion(add = 0.6)) +
  geom_hline(yintercept = IDENTITY_PSNR, linewidth = FIGURE_RULE_WIDTH,
             colour = FIGURE_RULE_COLOUR) +
  geom_point(aes(shape = seed, colour = mode),
             position = position_dodge(width = 0.55),
             size = 2.0, stroke = 0.6, fill = "white") +
  annotate("text", x = 0.45, y = IDENTITY_PSNR, hjust = 0, vjust = -0.35,
           size = FIGURE_ANNOTATION_SIZE, colour = FIGURE_RULE_COLOUR,
           family = FIGURE_FONT_FAMILY, lineheight = 0.9,
           label = sprintf("Degraded input, left alone:\n%.2f dB", IDENTITY_PSNR)) +
  scale_shape_manual(values = seed_shapes, guide = "none") +
  scale_colour_manual(values = mode_colours, guide = "none") +
  scale_y_continuous(limits = c(0, IDENTITY_PSNR * 1.28), expand = c(0, 0),
                     breaks = seq(0, 25, by = 5)) +
  labs(x = NULL, y = "Restored fidelity, PSNR (dB)",
       subtitle = "Every cell below the input") +
  rtx_theme() +
  theme(axis.text.x = element_text(lineheight = 0.9))

p <- patchwork::wrap_plots(panel_label(trajectories, "A"), panel_label(restored, "B"),
                           widths = c(2.3, 1))

save_fig(p, "fig11_init_ablation", width = FIGURE_TEXT_WIDTH_IN, height = 3.40)
