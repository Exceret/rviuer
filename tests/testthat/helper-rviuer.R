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
