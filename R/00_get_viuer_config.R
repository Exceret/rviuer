#' Create a terminal image print configuration
#'
#' @param transparent Whether to enable transparency. The original comment for
#'   this field was truncated; defaults to `FALSE`.
#' @param premultiplied_alpha Whether the alpha channel is assumed to be
#'   premultiplied for blending with the checkerboard background.
#'   Defaults to `FALSE`.
#' @param absolute_offset If `TRUE`, the x and y offsets are relative to the
#'   top left terminal corner. If `FALSE`, the y offset is relative to the
#'   cursor's position. Defaults to `FALSE`.
#' @param x X offset, a non-negative integer (u16). Defaults to `0L`.
#' @param y Y offset, an integer (i16). Can be negative only when
#'   `absolute_offset = FALSE`. Defaults to `0L`.
#' @param restore_cursor Take a note of the cursor position before printing and
#'   restore it when finished. Only useful when the image is redrawn in place
#'   (e.g. an animation): with `TRUE` the cursor is put back before the image,
#'   so the next prompt is printed over it. Defaults to `FALSE`.
#' @param width,height Image size in **terminal cells**, or `NULL` to fit the
#'   image to the terminal. When both are `NULL` the size is derived from the
#'   image and terminal dimensions, keeping the last row and column free so
#'   that a cell in the last column does not trigger the terminal's automatic
#'   line wrap. When only one of them is given, the other one follows from the
#'   aspect ratio of the image. Defaults to `NULL`.
#' @param truecolor Use truecolor if the terminal supports it.
#'   Defaults to `TRUE`.
#' @param use_kitty Use the Kitty protocol if the terminal supports it.
#'   Defaults to `TRUE`.
#' @param use_iterm Use the iTerm protocol if the terminal supports it.
#'   Defaults to `TRUE`.
#' @param use_sixel Use the Sixel protocol if the terminal supports it.
#'   Defaults to `TRUE`.
#'
#' @return A list of the configuration options.
#' @examples
#' get_viuer_config()
#'
#' @export
get_viuer_config <- function(
  transparent = FALSE,
  premultiplied_alpha = FALSE,
  absolute_offset = FALSE,
  x = 0L,
  y = 0L,
  restore_cursor = FALSE,
  width = NULL,
  height = NULL,
  truecolor = TRUE,
  use_kitty = TRUE,
  use_iterm = TRUE,
  use_sixel = TRUE
) {
  rlang::check_bool(transparent)
  rlang::check_bool(premultiplied_alpha)
  rlang::check_bool(absolute_offset)
  rlang::check_bool(restore_cursor)
  rlang::check_bool(truecolor)
  rlang::check_bool(use_kitty)
  rlang::check_bool(use_iterm)
  rlang::check_bool(use_sixel)

  rlang::check_number_whole(x)
  rlang::check_number_whole(y)
  if (!is.null(width)) {
    rlang::check_number_whole(width)
  }
  if (!is.null(height)) {
    rlang::check_number_whole(height)
  }

  list(
    transparent = transparent,
    premultiplied_alpha = premultiplied_alpha,
    absolute_offset = absolute_offset,
    x = x,
    y = y,
    restore_cursor = restore_cursor,
    width = width,
    height = height,
    truecolor = truecolor,
    use_kitty = use_kitty,
    use_iterm = use_iterm,
    use_sixel = use_sixel
  )
}
