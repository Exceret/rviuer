# A tiny RGB array used as image data in tests.
png_array <- function(n = 10L) {
  array(rep(c(1, 0.5, 0), each = n * n), dim = c(n, n, 3))
}

# Path to a temporary PNG file, deleted when the calling test finishes.
local_png_file <- function(n = 10L, env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".png", .local_envir = env)
  png::writePNG(png_array(n), target = path)
  path
}

# A PNG-encoded raw vector, as returned by `capture_plot()`.
png_raw <- function(n = 10L) {
  png::writePNG(png_array(n), target = raw())
}

# Configuration that only ever reaches the half-block printer: the graphics
# protocols are switched off so that a test never probes the terminal.
half_block_config <- function(...) {
  get_viuer_config(
    width = 2L,
    height = 1L,
    use_kitty = FALSE,
    use_iterm = FALSE,
    use_sixel = FALSE,
    ...
  )
}

# The half-block printer draws with escape sequences, so finding one in the
# captured lines means the drawing arrived.
has_escape <- function(lines) {
  any(grepl("\033", lines, fixed = TRUE))
}

# Run `code` with both R console streams captured.
#
# The inner sink takes the message stream, the outer one the output stream, so
# a drawing shows up in exactly one of the two returned character vectors.
# `code` must return its value invisibly: `capture.output()` prints visible
# values, which would add a stray `NULL` to the captured lines.
capture_streams <- function(code) {
  # `capture.output()` returns what it captured, so the inner result has to be
  # stored somewhere; an environment keeps it out of the caller's frame.
  captured <- new.env(parent = emptyenv())
  captured$messages <- character()

  output <- capture.output(
    {
      captured$messages <- capture.output(code, type = "message")
      invisible(NULL)
    },
    type = "output"
  )

  list(output = output, messages = captured$messages)
}
