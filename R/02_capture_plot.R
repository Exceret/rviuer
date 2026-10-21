#' Capture a plot as a PNG raw vector
#'
#' Evaluates plotting code on an in-memory ragg capture device and returns
#' the rendered image as a PNG-encoded raw vector. No temporary files are
#' created. If `expr` returns a visible value (e.g. a ggplot object), its
#' `print()` method is called, mimicking top-level auto-printing. Base
#' graphics draw directly onto the device.
#'
#' @param expr Plotting code: a single expression or a braced block.
#' @param width,height Image size, in units given by `units`.
#' @param units One of `"in"`, `"cm"`, `"mm"` or `"px"`.
#' @param res Resolution in pixels per inch.
#' @param bg Background colour.
#' @param ... Further arguments passed to [ragg::agg_capture()], such as
#'   `pointsize` or `scaling`.
#'
#' @return A raw vector containing a PNG image. If several pages were drawn,
#'   the last page is returned.
#' @export
#'
#' @examples
#' r1 <- capture_plot(plot(1:10))
#' r2 <- capture_plot(
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
#' )
#' r3 <- capture_plot({
#'   par(mfrow = c(1, 2))
#'   hist(rnorm(100))
#'   boxplot(mpg ~ cyl, data = mtcars)
#' })
capture_plot <- function(
  expr,
  width = 7L,
  height = 7L,
  units = c("in", "cm", "mm", "px"),
  res = 96L,
  bg = "white",
  ...
) {
  units <- rlang::arg_match(units)
  rlang::check_number_whole(width)
  rlang::check_number_whole(height)
  rlang::check_number_whole(res)

  prev_dev <- grDevices::dev.cur()
  dev <- list(
    capture = ragg::agg_capture(
      width = width,
      height = height,
      units = units,
      res = res,
      background = bg,
      ...
    ),
    id = grDevices::dev.cur()
  )
  on.exit(close_capture_device(dev$id, prev_dev), add = TRUE)

  # `expr` is a lazy promise, so it is only evaluated here, after the device
  # has been opened. Visible results are printed like at the console.

  vis <- withVisible(expr)
  if (vis$visible) {
    print(vis$value)
  }

  native <- dev$capture(native = TRUE)
  if (length(unique(as.vector(native))) <= 1L) {
    cli::cli_abort(c(
      x = "Nothing was drawn by {.arg expr}."
    ))
  }

  png::writePNG(native, target = raw())
}


close_capture_device <- function(dev_id, prev_dev) {
  if (dev_id %in% grDevices::dev.list()) {
    grDevices::dev.off(dev_id)
  }
  if (prev_dev %in% grDevices::dev.list()) {
    grDevices::dev.set(prev_dev)
  }
  invisible()
}
