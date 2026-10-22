test_that("pixel_font_add() adds a new glyph", {
  rows <- c("101", "111", "101", "111", "101")
  font <- pixel_font_add(char = "#", rows = rows)

  expect_type(font, "list")
  expect_length(font, length(pixel_font_3x5) + 1L)
  expect_identical(font[["#"]], rows)
  expect_identical(
    get_glyph("#", font),
    matrix(
      c(
        1L, 0L, 1L,
        1L, 1L, 1L,
        1L, 0L, 1L,
        1L, 1L, 1L,
        1L, 0L, 1L
      ),
      nrow = 5L,
      byrow = TRUE
    )
  )
})

test_that("pixel_font_add() leaves the original font untouched", {
  original <- pixel_font_3x5

  invisible(pixel_font_add(char = "#", rows = rep("111", 5L)))

  expect_identical(pixel_font_3x5, original)
  expect_false("#" %in% names(pixel_font_3x5))
})

test_that("pixel_font_add() replaces an existing glyph", {
  font <- pixel_font_add(char = "a", rows = rep("111", 5L))

  expect_length(font, length(pixel_font_3x5))
  expect_identical(font[["A"]], rep("111", 5L))
  expect_identical(get_glyph("A", font), matrix(1L, nrow = 5L, ncol = 3L))
})

test_that("pixel_font_add() stores letters in upper case", {
  font <- pixel_font_add(
    font = list(A = rep("000", 5L)),
    char = "q",
    rows = rep("010", 5L)
  )

  expect_named(font, c("A", "Q"))
  expect_identical(font[["Q"]], rep("010", 5L))
})

test_that("pixel_font_add() keeps the glyphs already in the font", {
  font <- pixel_font_add(char = "#", rows = rep("111", 5L))

  expect_identical(font[["A"]], pixel_font_3x5[["A"]])
  expect_identical(font[[" "]], pixel_font_3x5[[" "]])
})

test_that("pixel_font_add() can be chained", {
  font <- pixel_font_add(pixel_font_3x5, "#", rep("111", 5L))
  font <- pixel_font_add(font, "%", rep("101", 5L))

  expect_in(c("#", "%"), names(font))
  expect_length(font, length(pixel_font_3x5) + 2L)
  expect_identical(
    get_glyph("%", font),
    matrix(rep(c(1L, 0L, 1L), 5L), nrow = 5L, byrow = TRUE)
  )
})

test_that("pixel_font_add() aborts when `char` is not a single character", {
  rows <- rep("101", 5L)

  expect_snapshot(error = TRUE, pixel_font_add(char = 1L, rows = rows))
  expect_snapshot(error = TRUE, pixel_font_add(char = NA_character_, rows = rows))
  expect_snapshot(error = TRUE, pixel_font_add(char = c("a", "b"), rows = rows))
  expect_snapshot(error = TRUE, pixel_font_add(char = "ab", rows = rows))
})

test_that("pixel_font_add() aborts when `rows` is not a valid glyph", {
  expect_snapshot(error = TRUE, pixel_font_add(char = "#", rows = "101"))
  expect_snapshot(error = TRUE, pixel_font_add(char = "#", rows = 1:5))
  expect_snapshot(
    error = TRUE,
    pixel_font_add(char = "#", rows = c("101", "101", "101", "101"))
  )
  expect_snapshot(
    error = TRUE,
    pixel_font_add(char = "#", rows = c("101", "101", "101", "101", "102"))
  )
})
