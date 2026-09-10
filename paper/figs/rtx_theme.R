# Shared figure theme. R-first by workspace convention; do not add a
# matplotlib path to this tree.
#
# Keep one explicitly installed family for every glyph in the exported PDF.
# Arial is the manuscript's approved visual family.  The regular and bold
# files are resolved and checked before any panel is built; Cairo is then
# allowed to embed that family rather than asking fontconfig to substitute a
# second family for plot annotations.
FIGURE_FONT_FAMILY <- "Arial"

# Keep the visual hierarchy in one place.  The values are deliberately shared
# by every panel so a composed figure does not mix tiny inherited labels with
# larger ad-hoc annotations.  ggplot2 sizes are in points for theme elements
# and millimetres for geom text.
#
# These are printed sizes, not nominal ones.  Each canvas is emitted at its own
# printed width -- the text width times the \linewidth fraction the manuscript
# includes it at -- so TeX scales every figure by 1.0 and a value here reaches
# the page unchanged.  A panel that emits a different canvas width would
# silently rescale its own type and reintroduce the size drift these constants
# exist to prevent; figs/lib/emit.R refuses to write such a canvas.
FIGURE_TEXT_WIDTH_IN <- 6.5
FIGURE_BASE_SIZE <- 9.8
FIGURE_AXIS_TITLE_SIZE <- 8.9
FIGURE_AXIS_TEXT_SIZE <- 8.0
FIGURE_LEGEND_TITLE_SIZE <- 8.2
FIGURE_LEGEND_TEXT_SIZE <- 7.8
FIGURE_STRIP_TEXT_SIZE <- 8.4
FIGURE_TITLE_SIZE <- 10.7
FIGURE_SUBTITLE_SIZE <- 8.2
# geom text sizes are in millimetres: 2.5 mm is 7.1 pt, the smallest glyph the
# print standard allows, so no in-panel annotation may go below it.
FIGURE_ANNOTATION_SIZE <- 2.5
FIGURE_CELL_SIZE <- 2.5
FIGURE_VALUE_LABEL_SIZE <- 2.7
FIGURE_PANEL_LABEL_SIZE <- 10

# One palette for every panel, so a colour means the same thing wherever it is
# printed.  Okabe--Ito is distinguishable under the common colour-vision
# deficiencies; the roles below are the only ones the manuscript encodes.
FIGURE_PALETTE <- c(
  blue = "#0072B2", orange = "#E69F00", green = "#009E73",
  vermillion = "#D55E00", purple = "#CC79A7", sky = "#56B4E9",
  yellow = "#F0E442", black = "#000000"
)

# The two recorded camera groups are drawn the same way in every figure that
# shows crops: a filled circle for Canon and an open circle for Nikon, coloured
# as well so the two encodings are redundant and neither alone has to carry the
# distinction.
FIGURE_CAMERA_SHAPES <- c(Canon = 16, Nikon = 1)
FIGURE_CAMERA_COLOURS <- c(Canon = unname(FIGURE_PALETTE["blue"]),
                           Nikon = unname(FIGURE_PALETTE["vermillion"]))

# The three initialisation arms of the ablation.
FIGURE_INIT_COLOURS <- c(library_default = unname(FIGURE_PALETTE["blue"]),
                         dit_standard = unname(FIGURE_PALETTE["orange"]),
                         dit_zero = unname(FIGURE_PALETTE["green"]))

# What became of an input: the same three greys wherever an attempt is counted,
# so the census bars in two figures read alike.  White is the outcome that
# produced nothing, mid grey the one that produced a score.
FIGURE_OUTCOME_FILLS <- c(dropped = "white", unscored = "grey80", scored = "grey45")

# Reference rules: the trivial arm (input left alone, or equality) is always the
# same solid dark rule; a predeclared threshold is always the same dashed rule.
FIGURE_RULE_COLOUR <- "grey25"
FIGURE_RULE_WIDTH <- 0.45
FIGURE_THRESHOLD_LINETYPE <- "22"

# Numbers that appear as text inside a panel take a real minus sign, as the
# axis text already does, rather than a hyphen.
typeset_minus <- function(x) gsub("-", "\u2212", x, fixed = TRUE)

# Resolve the family before any panel is built.  A `family` string alone is not
# enough: on a different host Cairo can silently substitute a fallback when a
# regular or bold face is absent, and it does so per glyph rather than per
# figure, so a single character can arrive in a different typeface than the
# label around it.  The generator therefore fails closed if the two Arial faces
# or the Unicode glyphs used by the annotations cannot be resolved.  The minus
# sign is on the list because ggplot2 sets negative axis breaks with U+2212
# rather than a hyphen, and the mu because a plotmath unit resolves to it.
FIGURE_REQUIRED_GLYPHS <- c("\u03c3", "\u00d7", "\u00b1", "\u00b0", "\u2192",
                            "\u2190", "\u2191", "\u2193",
                            "\u03bc", "\u2212", "\u2013")

validate_figure_font <- function() {
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    stop("systemfonts is required to resolve the embedded figure font")
  }
  matches <- suppressWarnings(systemfonts::match_fonts(
    family = FIGURE_FONT_FAMILY,
    weight = c("normal", "bold")
  ))
  if (nrow(matches) != 2L || any(!file.exists(matches$path))) {
    stop("figure font family must provide installed regular and bold faces: ",
         FIGURE_FONT_FAMILY)
  }
  font_info <- systemfonts::font_info(path = matches$path)
  if (nrow(font_info) != 2L || any(font_info$family != FIGURE_FONT_FAMILY) ||
      !identical(as.logical(font_info$bold), c(FALSE, TRUE)) ||
      !identical(as.character(font_info$name), c("ArialMT", "Arial-BoldMT"))) {
    stop("figure font resolver returned a fallback or unexpected Arial face")
  }
  for (weight in c("normal", "bold")) {
    glyphs <- systemfonts::glyph_info(FIGURE_REQUIRED_GLYPHS,
                                      family = FIGURE_FONT_FAMILY,
                                      weight = weight)
    if (nrow(glyphs) != length(FIGURE_REQUIRED_GLYPHS) ||
        any(is.na(glyphs$index)) || any(glyphs$width <= 0)) {
      stop("figure font lacks one or more required Unicode glyphs at weight ",
           weight, ": ", FIGURE_FONT_FAMILY)
    }
  }
  invisible(matches$path)
}

validate_figure_font()

# ggplot2's newer defaults inherit `family` from the theme, but older releases
# leave text geoms at the host default.  Set both common text geoms explicitly so
# annotations that do not repeat `family =` cannot reintroduce a fallback.
ggplot2::update_geom_defaults("text", list(family = FIGURE_FONT_FAMILY))
ggplot2::update_geom_defaults("label", list(family = FIGURE_FONT_FAMILY))

rtx_theme <- function(base_size = FIGURE_BASE_SIZE) {
  ggplot2::theme_bw(base_size = base_size, base_family = FIGURE_FONT_FAMILY) +
    ggplot2::theme(
      text = ggplot2::element_text(family = FIGURE_FONT_FAMILY, colour = "black"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey90", linewidth = 0.25),
      panel.border = ggplot2::element_rect(colour = "black", linewidth = 0.3),
      axis.ticks = ggplot2::element_line(linewidth = 0.3),
      axis.title = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                         size = FIGURE_AXIS_TITLE_SIZE),
      axis.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                        size = FIGURE_AXIS_TEXT_SIZE),
      legend.title = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                           size = FIGURE_LEGEND_TITLE_SIZE),
      legend.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                          size = FIGURE_LEGEND_TEXT_SIZE),
      strip.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                         size = FIGURE_STRIP_TEXT_SIZE),
      # Every subtitle in the set is the same size and colour, so a composed
      # figure does not carry three sizes of the same kind of line.
      plot.subtitle = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                            size = FIGURE_SUBTITLE_SIZE,
                                            colour = "grey25"),
      legend.key = ggplot2::element_blank(),
      legend.key.size = grid::unit(9, "pt"),
      legend.margin = ggplot2::margin(t = 1, r = 2, b = 1, l = 2),
      legend.box.spacing = grid::unit(5, "pt"),
      strip.background = ggplot2::element_blank()
    )
}

# Apply a panel label to one member of a composed figure.  A ggplot plot tag
# with `plot.tag.location = "panel"` is anchored to the panel viewport itself;
# hjust=1 and vjust=0 put the right/bottom edges on the upper-left spine and
# extend the glyph into the outer top/left margin.  This is deliberately not a
# data-space annotation: it stays outside the plotting region for linear, log,
# discrete and faceted scales alike, and patchwork keeps one tag per composed
# panel.
#
# A caption that says "left" describes where a panel happened to land in one
# composition; a caption that says "Panel A" describes the panel.  The label is
# what lets the caption stay self-contained, so every composed figure in this
# tree carries one.
#
# The title and subtitle are optional: a composed panel that already reads from
# its axes gets a label without acquiring a heading it did not have, and a
# panel that set its own subtitle keeps it.  (Passing NULL through labs() would
# delete an existing subtitle, which is how three composed figures lost the
# denominators their panels had printed.)
panel_label <- function(plot, label, title = NULL, subtitle = NULL) {
  if (!is.null(subtitle)) {
    subtitle <- paste(strwrap(subtitle, width = 48), collapse = "\n")
    plot <- plot + ggplot2::labs(subtitle = subtitle)
  }
  if (!is.null(title)) {
    plot <- plot + ggplot2::labs(title = title)
  }
  plot +
    ggplot2::labs(tag = label) +
    ggplot2::theme(
      plot.title.position = "panel",
      plot.title = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 0.5,
        size = FIGURE_TITLE_SIZE, face = "plain",
        margin = ggplot2::margin(b = 2.5)
      ),
      # The subtitle clears the band the tag occupies above the panel corner,
      # so a subtitle as wide as its panel cannot run into the tag.
      plot.subtitle = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 0.5,
        size = FIGURE_SUBTITLE_SIZE, colour = "grey25",
        lineheight = 0.95, margin = ggplot2::margin(b = 12)
      ),
      plot.tag.location = "panel",
      plot.tag.position = c(0, 1),
      plot.tag = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 1, vjust = 0,
        size = FIGURE_PANEL_LABEL_SIZE, face = "bold",
        margin = ggplot2::margin(0, 0, 0, 0)
      ),
      # Keep enough outer room for the label's ascender and leftward extent.
      plot.margin = ggplot2::margin(t = 12, r = 6, b = 4, l = 12)
    )
}
