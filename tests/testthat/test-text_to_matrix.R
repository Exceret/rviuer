test_that("text_to_matrix() renders one glyph per character", {
  expect_identical(text_to_matrix("a"), get_glyph("a"))

  m <- text_to_matrix("rviuer")

  expect_identical(dim(m), c(5L, 23L))
  expect_type(m, "integer")
  expect_true(all(m %in% c(0L, 1L)))
})

test_that("text_to_matrix() separates characters with `spacing` columns", {
  expect_identical(dim(text_to_matrix("abc", spacing = 0L)), c(5L, 9L))
  expect_identical(dim(text_to_matrix("abc")), c(5L, 11L))
  expect_identical(dim(text_to_matrix("abc", spacing = 2L)), c(5L, 13L))

  # The gap columns are empty.
  expect_identical(text_to_matrix("abc")[, 4L], rep(0L, 5L))
})

test_that("text_to_matrix() stacks lines separated by `line_spacing` rows", {
  expect_identical(dim(text_to_matrix("hi\nyo")), c(11L, 7L))
  expect_identical(
    dim(text_to_matrix("hi\nyo", line_spacing = 0L)),
    c(10L, 7L)
  )
  expect_identical(
    dim(text_to_matrix("hi\nyo", line_spacing = 2L)),
    c(12L, 7L)
  )
})

test_that("text_to_matrix() pads short lines to the widest line", {
  m <- text_to_matrix("i\nww")

  expect_identical(dim(m), c(11L, 7L))
  expect_identical(m[6L, ], rep(0L, 7L))
  expect_identical(m[1:5, 4:7], matrix(0L, nrow = 5L, ncol = 4L))
})

test_that("text_to_matrix() labels letters by index when `index = TRUE`", {
  m <- text_to_matrix("ab", index = TRUE)

  expect_identical(m[, 1:3], get_glyph("a"))
  expect_identical(m[, 4L], rep(0L, 5L))
  expect_identical(m[, 5:7], get_glyph("b") * 2L)
})

test_that("text_to_matrix() numbers letters separately on each line", {
  m <- text_to_matrix("a\na", index = TRUE)

  expect_identical(m[1:5, ], get_glyph("a"))
  expect_identical(m[7:11, ], get_glyph("a"))
})

test_that("text_to_matrix() handles the empty string", {
  expect_identical(dim(text_to_matrix("")), c(5L, 0L))
})

test_that("text_to_matrix() accepts a custom font", {
  font <- pixel_font_add(char = "#", rows = rep("111", 5L))

  expect_identical(dim(text_to_matrix("##", font)), c(5L, 7L))
  expect_identical(dim(text_to_matrix("##", font, spacing = 0L)), c(5L, 6L))
})

test_that("text_to_matrix() aborts when `text` is not a single string", {
  expect_snapshot(error = TRUE, text_to_matrix(1L))
  expect_snapshot(error = TRUE, text_to_matrix(NULL))
  expect_snapshot(error = TRUE, text_to_matrix(NA_character_))
  expect_snapshot(error = TRUE, text_to_matrix(c("a", "b")))
})

test_that("text_to_matrix() aborts on negative spacing", {
  expect_snapshot(error = TRUE, text_to_matrix("a", spacing = -1L))
  expect_snapshot(error = TRUE, text_to_matrix("a", line_spacing = -1L))
})

test_that("text_to_matrix() aborts on characters the font does not define", {
  expect_snapshot(error = TRUE, text_to_matrix("a~"))
})
