# Figure 11. The training objective under three initialisations, three seeds
# each. The record holds two summary points per cell -- the mean over the first
# ten steps and the mean over the last ten -- and the last step; the trajectory
# drawn is those points joined, not a per-step curve. The rule at unity is what
# a network contributing nothing produces; the dashed rule is the predeclared
# stall threshold.

if (!exists("init_cells")) stop("initialisation cells were not loaded")

mode_labels <- c(library_default = "Library default (gates not zero)",
                 dit_standard = "Standard scheme (gates not zero)",
                 dit_zero = "Zero-gated scheme (gates exactly zero)")

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

p <- ggplot(traj, aes(x = order, y = loss, group = seed, linetype = seed, shape = seed)) +
  geom_hline(yintercept = 1, linewidth = 0.4, colour = "grey25") +
  geom_hline(yintercept = INIT_THRESHOLD, linewidth = 0.4, linetype = "22", colour = "grey40") +
  geom_line(linewidth = 0.45, colour = "black") +
  geom_point(size = 1.8, stroke = 0.5, fill = "white", colour = "black") +
  facet_wrap(~mode, nrow = 1) +
  scale_x_continuous(breaks = 1:3, labels = c("First ten\nsteps", "Last ten\nsteps", "Final\nstep"),
                     expand = expansion(mult = 0.12)) +
  scale_shape_manual(values = c(21, 22, 24), name = "Seed") +
  scale_linetype_manual(values = c("solid", "42", "12"), name = "Seed") +
  labs(x = NULL, y = "Training objective (mean squared error)",
       subtitle = sprintf(
         "%d cells, %d steps each; solid rule = unity, dashed rule = stall threshold %.2f",
         nrow(init_cells), init_predecl$design$training$steps, INIT_THRESHOLD)) +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        legend.position = "bottom", legend.title = element_text(size = 7),
        legend.text = element_text(size = 7), legend.key.size = unit(10, "pt"),
        axis.text.x = element_text(size = 7))

save_fig(p, "fig11_init_ablation", width = FIGURE_TEXT_WIDTH_IN, height = 2.7)
