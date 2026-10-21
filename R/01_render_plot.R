#' Render an image in the terminal
#'
#' @description
#' `render_plot()` is an S3 generic that draws an image in the terminal using
#' whichever graphics protocol the terminal supports (iTerm, Kitty or Sixel),
#' falling back to coloured half-blocks. The method chosen for `x` decides how
#' the image is read.
#'
#' @param x An image source. The class of `x` selects the method:
#' * `character`: a path to an image file, which is read from disk.
#' * `raw`: a PNG-encoded image, such as the value returned by
#'   [capture_plot()]. The bytes are always decoded as PNG.
#' @param config A configuration list, as built by [get_viuer_config()]. It
#'   controls transparency, offsets, size and the protocols that are enabled.
#' @param ... Further arguments passed on to [print_image()].
#'
#' @return `TRUE` if the image is successfully printed.`
#'
#' @seealso [get_viuer_config()] for the printing options, [capture_plot()] for
#'   rendering a plot to a PNG raw vector, and [print_image()] for the entry
#'   point shared by every method.
#'
#' @name render_plot
#' @export
render_plot <- function(x, config = get_viuer_config(), ...) {
  UseMethod("render_plot")
}

#' @rdname render_plot
#' @export
render_plot.default <- function(x, config = get_viuer_config(), ...) {
  available_classes <- sub(
    "render_plot\\.",
    "",
    x = utils::methods("render_plot") |> as.character()
  )
  current_class <- class(x)
  cli::cli_abort(c(
    x = "Class {.cls {x}} is not supported",
    i = "Available classes: {.cls {available_classes}}"
  ))
}

#' @rdname render_plot
#' @export
render_plot.character <- function(x, config = get_viuer_config(), ...) {
  dots <- list(...)
  if (!file.exists(x)) {
    cli::cli_abort(c(x = "{.path {x}} not exist"))
  }
  if (!is.null(dots$raw)) {
    cli::cli_abort(c(
      x = "`raw` should not be provided when rendering plot from file"
    ))
  }
  print_image(config = config, file_path = x, ...)
  invisible(TRUE)
}

#' @rdname render_plot
#' @export
render_plot.raw <- function(x, config = get_viuer_config(), ...) {
  dots <- list(...)
  if (!is.null(dots$file_path)) {
    cli::cli_abort(c(
      x = "`file_path` should not be provided when rendering plot from R"
    ))
  }
  print_image(config = config, raw = x, ...)
  invisible(TRUE)
}
