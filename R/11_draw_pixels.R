#' Convert text to a pixel matrix
#'
#' Looks up every character of `text` in `font` and joins the 5 x 3 glyphs
#' side by side. A newline (`"\n"`) starts a new line of pixels.
#'
#' @param text A single string.
#' @param font A pixel font; see [pixel_font_3x5].
#' @param spacing Number of empty columns between two characters.
#' @param line_spacing Number of empty rows between two lines of text.
#' @param index If `TRUE`, the filled pixels of the n-th character of a line
#'   hold the value `n` instead of `1`. This is used to colour each letter
#'   separately.
#'
#' @return An integer matrix. Empty pixels are `0`.
#' @seealso [get_glyph()], [matrix_to_pixels()], [draw_pixels()]
#' @examples
#' dim(text_to_matrix("rviuer"))  # 5 rows, 6 * 3 + 5 = 23 columns
#' text_to_matrix("hi\nyo", line_spacing = 2)
text_to_matrix <- function(
  text,
  font = pixel_font_3x5,
  spacing = 1L,
  line_spacing = 1L,
  index = FALSE
) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) {
    cli::cli_abort("{.arg text} must be a single string.")
  }
  spacing <- as.integer(spacing)
  line_spacing <- as.integer(line_spacing)
  if (spacing < 0L || line_spacing < 0L) {
    cli::cli_abort(
      "{.arg spacing} and {.arg line_spacing} must be non-negative."
    )
  }

  gap_cols <- matrix(0L, nrow = 5L, ncol = spacing)

  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  if (length(lines) == 0L) {
    lines <- ""
  }

  line_mats <- lapply(lines, function(line) {
    chars <- strsplit(line, "", fixed = TRUE)[[1]]
    if (length(chars) == 0L) {
      return(matrix(0L, nrow = 5L, ncol = 0L))
    }
    parts <- list()
    for (i in seq_along(chars)) {
      glyph <- get_glyph(chars[i], font)
      if (index) {
        glyph <- glyph * i
      }
      parts[[length(parts) + 1L]] <- glyph
      if (i < length(chars)) parts[[length(parts) + 1L]] <- gap_cols
    }
    do.call(cbind, parts)
  })

  # Pad every line to the same width, then stack the lines vertically.
  width <- max(vapply(line_mats, ncol, integer(1)))
  line_mats <- lapply(line_mats, function(m) {
    if (ncol(m) < width) cbind(m, matrix(0L, 5L, width - ncol(m))) else m
  })
  gap_rows <- matrix(0L, nrow = line_spacing, ncol = width)

  parts <- list()
  for (i in seq_along(line_mats)) {
    parts[[length(parts) + 1L]] <- line_mats[[i]]
    if (i < length(line_mats)) parts[[length(parts) + 1L]] <- gap_rows
  }
  do.call(rbind, parts)
}

#' Convert a pixel matrix to a long data frame
#'
#' @param m A matrix of pixel values, e.g. from [text_to_matrix()].
#'
#' @return A data frame with one row per pixel and the columns `row`, `col`
#'   (both starting at 1, `row` counted from the top) and `value`.
#' @examples
#' head(matrix_to_pixels(text_to_matrix("a")))
matrix_to_pixels <- function(m) {
  if (!is.matrix(m)) {
    cli::cli_abort("{.arg m} must be a matrix.")
  }
  data.frame(
    row = as.vector(row(m)),
    col = as.vector(col(m)),
    value = as.vector(m)
  )
}

#' Draw a pixel matrix with ggplot2
#'
#' @param m A matrix of pixel values. `0` is an empty pixel; any positive
#'   value is a filled pixel. When `color_by = "letter"`, different positive
#'   values get different colours.
#' @inheritParams draw_pixels
#'
#' @return A `ggplot` object.
#' @seealso [text_to_matrix()], [draw_pixels()]
draw_matrix <- function(
  m,
  fill = "steelblue",
  background = "white",
  border = "grey85",
  border_width = 0.4,
  color_by = c("none", "letter"),
  palette = NULL
) {
  rlang::check_installed("ggplot2")
  color_by <- rlang::arg_match(color_by)
  df <- matrix_to_pixels(m)

  if (color_by == "none") {
    df$value[df$value > 0] <- 1L
    colors <- c("0" = background, "1" = fill)
  } else {
    n <- max(df$value, 1L)
    if (is.null(palette)) {
      palette <- grDevices::hcl.colors(n, "Dark 3")
    }
    colors <- c(
      "0" = background,
      stats::setNames(rep_len(palette, n), seq_len(n))
    )
  }
  df$value <- as.character(df$value)

  col <- row <- value <- NULL # ease NOTE
  ggplot2::ggplot(
    df,
    ggplot2::aes(x = col, y = row, fill = value)
  ) +
    ggplot2::geom_tile(color = border, linewidth = border_width) +
    ggplot2::scale_fill_manual(values = colors, guide = "none") +
    ggplot2::scale_y_reverse() +
    ggplot2::coord_fixed() +
    ggplot2::theme_void()
}

#' Draw text as a 3 x 5 pixel grid
#'
#' The main entry point: converts `text` to a pixel matrix with
#' [text_to_matrix()] and plots it with [draw_matrix()].
#'
#' @inheritParams text_to_matrix
#' @param fill Fill colour of the filled pixels.
#' @param background Fill colour of the empty pixels. Use `NA` for none.
#' @param border Colour of the grid lines. Use `NA` for none.
#' @param border_width Width of the grid lines.
#' @param color_by Either `"none"` (all letters share `fill`) or `"letter"`
#'   (each character gets its own colour).
#' @param palette A character vector of colours used when
#'   `color_by = "letter"`. It is recycled if shorter than the text. The
#'   default is `grDevices::hcl.colors(n, "Dark 3")`.
#'
#' @return A `ggplot` object, so it can be extended with further layers or
#'   saved with [ggplot2::ggsave()].
#' @seealso [pixel_font_3x5], [pixel_font_add()]
#' @examples
#' draw_pixels("rviuer")
#' draw_pixels("rviuer", color_by = "letter")
#' draw_pixels("hello\nworld", fill = "tomato", border = NA)
#' @export
draw_pixels <- function(
  text,
  font = pixel_font_3x5,
  spacing = 1L,
  line_spacing = 1L,
  fill = "steelblue",
  background = "white",
  border = "grey85",
  border_width = 0.4,
  color_by = c("none", "letter"),
  palette = NULL
) {
  color_by <- rlang::arg_match(color_by)
  m <- text_to_matrix(
    text,
    font = font,
    spacing = spacing,
    line_spacing = line_spacing,
    index = color_by == "letter"
  )
  draw_matrix(
    m,
    fill = fill,
    background = background,
    border = border,
    border_width = border_width,
    color_by = color_by,
    palette = palette
  )
}
