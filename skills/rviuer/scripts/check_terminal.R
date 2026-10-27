#!/usr/bin/env Rscript
# Diagnose rviuer terminal support and sizing.
#
# Usage:
#   Rscript check_terminal.R            # report only
#   Rscript check_terminal.R --render   # also render a small test image
#
# Detection mirrors viuer 0.9.2 (see references/terminal-support.md).

args <- commandArgs(trailingOnly = TRUE)
do_render <- "--render" %in% args

env_or_unset <- function(name) {
  value <- Sys.getenv(name, unset = "")
  if (nzchar(value)) value else "<unset>"
}

rule <- function(title) {
  cat("\n", title, "\n", strrep("=", nchar(title)), "\n", sep = "")
}

term <- Sys.getenv("TERM", unset = "")
term_program <- Sys.getenv("TERM_PROGRAM", unset = "")
lc_terminal <- Sys.getenv("LC_TERMINAL", unset = "")
colorterm <- Sys.getenv("COLORTERM", unset = "")

iterm <- grepl("iTerm|WezTerm|mintty|rio|WarpTerminal", term_program) ||
  grepl("iTerm|WezTerm|mintty|rio", lc_terminal)
kitty <- grepl("kitty|ghostty", term)
sixel_term <- term %in%
  c("mlterm", "yaft-256color", "foot", "foot-extra", "eat-truecolor", "rio") ||
  term_program == "MacTerm"
truecolor <- grepl("truecolor|24bit", colorterm)

protocol <- if (iterm) {
  "iTerm"
} else if (kitty) {
  "Kitty"
} else if (sixel_term) {
  "Sixel-capable terminal, but this rviuer build has no sixel feature -> half-blocks"
} else {
  "half-blocks (ANSI)"
}

rule("Environment")
for (name in c(
  "TERM",
  "TERM_PROGRAM",
  "LC_TERMINAL",
  "COLORTERM",
  "KITTY_WINDOW_ID"
)) {
  cat(sprintf("  %-16s %s\n", name, env_or_unset(name)))
}

rule("Detection")
cat("  stdout is a TTY: ", isatty(stdout()), "\n", sep = "")
cat("  interactive():   ", interactive(), "\n", sep = "")
cat("  protocol:        ", protocol, "\n", sep = "")
cat(
  "  colour depth:    ",
  if (truecolor) "truecolor (24-bit)" else "256 colours",
  "\n",
  sep = ""
)

if (!requireNamespace("rviuer", quietly = TRUE)) {
  cat("\nrviuer is not installed: pak::pak(\"Exceret/rviuer\")\n")
  quit(status = 0)
}

rule("Terminal size (cells)")
size <- rviuer:::terminal_size()
cat("  width:  ", size$width, "\n", sep = "")
cat("  height: ", size$height, "\n", sep = "")
cat("  (80 x 24 means no TTY was detected)\n")

rule("Fit example: 1600 x 900 px image")
cat(
  "  cells: ",
  paste(
    rviuer:::fit_terminal_cells(1600L, 900L, size$width, size$height),
    collapse = " x "
  ),
  "\n",
  sep = ""
)

if (!do_render) {
  cat("\nRun again with --render to print a test image.\n")
  quit(status = 0)
}

rule("Test render")
if (!isatty(stdout())) {
  cat(
    "  Skipped: stdout is not a terminal, escape codes would only pollute the log.\n"
  )
  quit(status = 0)
}

test_render <- function() {
  rows <- 40L
  cols <- 60L
  checkers <- outer(seq_len(rows) %/% 5L, seq_len(cols) %/% 5L, `+`) %% 2L
  grey <- ifelse(checkers == 0L, 220L, 40L) / 255

  img <- array(1, dim = c(rows, cols, 4L))
  img[,, 1L] <- grey
  img[,, 2L] <- grey
  img[,, 3L] <- grey

  path <- tempfile(fileext = ".png")
  on.exit(unlink(path), add = TRUE)
  png::writePNG(img, target = path)

  ok <- rviuer::render_plot(
    path,
    config = rviuer::get_viuer_config(width = 30L)
  )
  cat("\n  render_plot() returned: ", ok, "\n", sep = "")
  cat("  A grey checkerboard above means the pipeline works.\n")
  invisible(ok)
}

test_render()
