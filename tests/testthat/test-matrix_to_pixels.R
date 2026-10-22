test_that("matrix_to_pixels() returns one row per pixel", {
  df <- matrix_to_pixels(get_glyph("a"))

  expect_s3_class(df, "data.frame")
  expect_named(df, c("row", "col", "value"))
  expect_identical(nrow(df), 15L)
})

test_that("matrix_to_pixels() counts rows from the top and columns from the left", {
  df <- matrix_to_pixels(matrix(1:4, nrow = 2L))

  expect_identical(df$row, c(1L, 2L, 1L, 2L))
  expect_identical(df$col, c(1L, 1L, 2L, 2L))
  expect_identical(df$value, 1:4)
})

test_that("matrix_to_pixels() keeps the pixel values", {
  m <- matrix(c(0L, 1L, 2L, 0L), nrow = 2L)

  expect_identical(sort(matrix_to_pixels(m)$value), c(0L, 0L, 1L, 2L))
})

test_that("matrix_to_pixels() handles empty matrices", {
  df <- matrix_to_pixels(matrix(integer(), nrow = 0L, ncol = 0L))

  expect_identical(nrow(df), 0L)
  expect_named(df, c("row", "col", "value"))
})

test_that("matrix_to_pixels() aborts when `m` is not a matrix", {
  expect_snapshot(error = TRUE, matrix_to_pixels(1:4))
  expect_snapshot(error = TRUE, matrix_to_pixels(data.frame(a = 1)))
  expect_snapshot(error = TRUE, matrix_to_pixels(NULL))
})
