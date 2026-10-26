#' 3 x 5 pixel font
#'
#' A named list that stores the alphabet. Each element is a character vector
#' of five strings (one per row, top to bottom), and each string has three
#' characters: `"1"` is a filled pixel and `"0"` is an empty pixel.
#'
#' The list holds the letters `A-Z`, the digits `0-9`, the space and a few
#' punctuation marks. Letters are stored in upper case; look-ups through
#' [get_glyph()] are case-insensitive.
#'
#' @format A named list of character vectors, each of length 5, whose
#'   elements are strings of length 3.
#' @seealso [get_glyph()], [pixel_font_add()], [draw_pixels()]
#' @examples
#' \donttest{
#' pixel_font_3x5[["A"]]
#' }
#' @export
pixel_font_3x5 <- list(
  # ---- letters ------------------------------------------------------------
  A = c("010", "101", "111", "101", "101"),
  B = c("110", "101", "110", "101", "110"),
  C = c("011", "100", "100", "100", "011"),
  D = c("110", "101", "101", "101", "110"),
  E = c("111", "100", "110", "100", "111"),
  F = c("111", "100", "110", "100", "100"),
  G = c("011", "100", "101", "101", "011"),
  H = c("101", "101", "111", "101", "101"),
  I = c("111", "010", "010", "010", "111"),
  J = c("001", "001", "001", "101", "010"),
  K = c("101", "101", "110", "101", "101"),
  L = c("100", "100", "100", "100", "111"),
  M = c("101", "111", "111", "101", "101"),
  N = c("110", "101", "101", "101", "101"),
  O = c("010", "101", "101", "101", "010"),
  P = c("110", "101", "110", "100", "100"),
  Q = c("010", "101", "101", "110", "011"),
  R = c("111", "101", "110", "101", "101"),
  S = c("011", "100", "010", "001", "110"),
  T = c("111", "010", "010", "010", "010"),
  U = c("101", "101", "101", "101", "111"),
  V = c("101", "101", "101", "101", "010"),
  W = c("101", "101", "111", "111", "101"),
  X = c("101", "101", "010", "101", "101"),
  Y = c("101", "101", "010", "010", "010"),
  Z = c("111", "001", "010", "100", "111"),
  # ---- digits -------------------------------------------------------------
  `0` = c("111", "101", "101", "101", "111"),
  `1` = c("010", "110", "010", "010", "111"),
  `2` = c("110", "001", "010", "100", "111"),
  `3` = c("110", "001", "010", "001", "110"),
  `4` = c("101", "101", "111", "001", "001"),
  `5` = c("111", "100", "110", "001", "110"),
  `6` = c("011", "100", "111", "101", "111"),
  `7` = c("111", "001", "010", "010", "010"),
  `8` = c("111", "101", "111", "101", "111"),
  `9` = c("111", "101", "111", "001", "110"),
  # ---- punctuation --------------------------------------------------------
  ` ` = c("000", "000", "000", "000", "000"),
  `.` = c("000", "000", "000", "000", "010"),
  `,` = c("000", "000", "000", "010", "100"),
  `-` = c("000", "000", "111", "000", "000"),
  `:` = c("000", "010", "000", "010", "000"),
  `!` = c("010", "010", "010", "000", "010"),
  `?` = c("110", "001", "010", "000", "010")
)

#' Check that a glyph definition is valid
#'
#' @param rows A character vector of five strings of three `"0"`/`"1"`
#'   characters each.
#' @return `TRUE`, invisibly. An error is raised if the definition is invalid.
#' @keywords internal
check_glyph <- function(rows) {
  ok <- is.character(rows) &&
    length(rows) == 5L &&
    all(grepl("^[01]{3}$", rows))
  if (!ok) {
    cli::cli_abort(
      "A glyph must be a character vector of 5 strings, each made of exactly {.val 3} characters from {.val 0} and {.val 1}."
    )
  }
  invisible(TRUE)
}

#' Get a glyph as a pixel matrix
#'
#' Looks up one character in a pixel font and returns it as a 5 x 3 integer
#' matrix of zeros and ones.
#'
#' @param char A single character. Letters are matched case-insensitively.
#' @param font A pixel font, i.e. a named list as described in
#'   [pixel_font_3x5]. Defaults to [pixel_font_3x5].
#'
#' @return An integer matrix with 5 rows and 3 columns, where `1` marks a
#'   filled pixel.
#' @seealso [pixel_font_3x5], [text_to_matrix()]
#' @examples
#' \donttest{
#' get_glyph("a")
#' }
#' @export
get_glyph <- function(char, font = pixel_font_3x5) {
  if (
    !is.character(char) ||
      length(char) != 1L ||
      is.na(char) ||
      nchar(char) != 1L
  ) {
    cli::cli_abort("{.arg char} must be a single character.")
  }
  key <- toupper(char)
  if (!key %in% names(font)) {
    cli::cli_abort(
      "No glyph defined for {.val {char}}. See {.code names(pixel_font_3x5)} for the available characters."
    )
  }
  rows <- font[[key]]
  check_glyph(rows)
  do.call(rbind, lapply(strsplit(rows, "", fixed = TRUE), as.integer))
}

#' Add or replace a glyph in a pixel font
#'
#' Returns a modified copy of `font`; the original is left untouched.
#'
#' @inheritParams get_glyph
#' @param char A single character to define. Letters are stored in upper case.
#' @param rows A character vector of five strings, each made of three
#'   characters from `"0"` and `"1"` (top row first).
#'
#' @return The updated font (a named list).
#' @examples
#' \donttest{
#' font <- pixel_font_add(pixel_font_3x5, "#", c("101", "111", "101", "111", "101"))
#' get_glyph("#", font)
#' }
#' @export
pixel_font_add <- function(font = pixel_font_3x5, char, rows) {
  if (
    !is.character(char) ||
      length(char) != 1L ||
      is.na(char) ||
      nchar(char) != 1L
  ) {
    cli::cli_abort("{.arg char} must be a single character.")
  }
  check_glyph(rows)
  font[[toupper(char)]] <- rows
  font
}
