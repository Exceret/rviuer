test_that("get_glyph() returns the 5 x 3 matrix of a glyph", {
  m <- get_glyph("A")

  expect_true(is.matrix(m))
  expect_identical(dim(m), c(5L, 3L))
  expect_type(m, "integer")
  expect_true(all(m %in% c(0L, 1L)))
  expect_identical(
    m,
    matrix(
      c(
        0L, 1L, 0L,
        1L, 0L, 1L,
        1L, 1L, 1L,
        1L, 0L, 1L,
        1L, 0L, 1L
      ),
      nrow = 5L,
      byrow = TRUE
    )
  )
})

test_that("get_glyph() looks letters up case-insensitively", {
  expect_identical(get_glyph("a"), get_glyph("A"))
  expect_identical(get_glyph("z"), get_glyph("Z"))
  expect_identical(get_glyph("A")[1L, ], c(0L, 1L, 0L))
})

test_that("get_glyph() reads digits and punctuation", {
  expect_identical(
    get_glyph("7"),
    matrix(
      c(
        1L, 1L, 1L,
        0L, 0L, 1L,
        0L, 1L, 0L,
        0L, 1L, 0L,
        0L, 1L, 0L
      ),
      nrow = 5L,
      byrow = TRUE
    )
  )
  expect_identical(get_glyph(" "), matrix(0L, nrow = 5L, ncol = 3L))
})

test_that("get_glyph() accepts a custom font", {
  font <- list("+" = c("001", "010", "111", "010", "001"))

  expect_identical(
    get_glyph("+", font),
    matrix(
      c(
        0L, 0L, 1L,
        0L, 1L, 0L,
        1L, 1L, 1L,
        0L, 1L, 0L,
        0L, 0L, 1L
      ),
      nrow = 5L,
      byrow = TRUE
    )
  )
})

test_that("get_glyph() aborts when `char` is not a single character", {
  expect_snapshot(error = TRUE, get_glyph(1L))
  expect_snapshot(error = TRUE, get_glyph(NULL))
  expect_snapshot(error = TRUE, get_glyph(factor("a")))
  expect_snapshot(error = TRUE, get_glyph(NA_character_))
  expect_snapshot(error = TRUE, get_glyph(c("a", "b")))
  expect_snapshot(error = TRUE, get_glyph(""))
  expect_snapshot(error = TRUE, get_glyph("ab"))
})

test_that("get_glyph() aborts on characters the font does not define", {
  expect_snapshot(error = TRUE, get_glyph("~"))
  expect_snapshot(
    error = TRUE,
    get_glyph("x", font = list(A = pixel_font_3x5[["A"]]))
  )
})

test_that("get_glyph() validates the glyph stored in the font", {
  expect_snapshot(error = TRUE, get_glyph("A", font = list(A = "010")))
  expect_snapshot(
    error = TRUE,
    get_glyph("A", font = list(A = c("010", "101", "111", "101", "102")))
  )
  expect_snapshot(error = TRUE, get_glyph("A", font = list(A = 1:5)))
})
