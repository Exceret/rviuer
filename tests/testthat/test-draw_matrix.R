test_that("draw_matrix() returns a ggplot", {
  skip_if_not_installed("ggplot2")

  expect_s3_class(draw_matrix(get_glyph("k")), "ggplot")
})

test_that("draw_matrix() draws one tile per pixel", {
  skip_if_not_installed("ggplot2")

  m <- get_glyph("k")
  built <- ggplot2::ggplot_build(draw_matrix(m))$data[[1]]

  expect_identical(nrow(built), length(m))
})

test_that("draw_matrix() maps filled and empty pixels to two colours", {
  skip_if_not_installed("ggplot2")

  m <- get_glyph("k")
  built <- ggplot2::ggplot_build(
    draw_matrix(m, fill = "#FF0000", background = "#0000FF")
  )$data[[1]]

  expect_setequal(unique(built$fill), c("#FF0000", "#0000FF"))
  expect_identical(sum(built$fill == "#FF0000"), sum(m > 0L))
})

test_that("draw_matrix() colours letters separately when asked", {
  skip_if_not_installed("ggplot2")

  m <- text_to_matrix("ab", index = TRUE)
  built <- ggplot2::ggplot_build(
    draw_matrix(m, color_by = "letter", palette = c("red", "blue"))
  )$data[[1]]

  expect_setequal(unique(built$fill), c("white", "red", "blue"))
  expect_identical(sum(built$fill == "red"), sum(m == 1L))
  expect_identical(sum(built$fill == "blue"), sum(m == 2L))
})

test_that("draw_matrix() defaults to an hcl palette", {
  skip_if_not_installed("ggplot2")

  m <- text_to_matrix("ab", index = TRUE)
  built <- ggplot2::ggplot_build(
    draw_matrix(m, color_by = "letter")
  )$data[[1]]
  fills <- setdiff(unique(built$fill), "white")

  expect_length(fills, 2L)
  expect_in(fills, grDevices::hcl.colors(2L, "Dark 3"))
})

test_that("draw_matrix() keeps the grid lines by default", {
  skip_if_not_installed("ggplot2")

  built <- ggplot2::ggplot_build(
    draw_matrix(get_glyph("k"), border = "#CCCCCC", border_width = 1)
  )$data[[1]]

  expect_true(all(built$colour == "#CCCCCC"))
})

test_that("draw_matrix() drops the grid lines when `border = NA`", {
  skip_if_not_installed("ggplot2")

  built <- ggplot2::ggplot_build(
    draw_matrix(get_glyph("k"), border = NA)
  )$data[[1]]

  expect_true(all(is.na(built$colour)))
})

test_that("draw_matrix() aborts on invalid input", {
  skip_if_not_installed("ggplot2")

  expect_snapshot(error = TRUE, draw_matrix(1:4))
  expect_snapshot(error = TRUE, draw_matrix(get_glyph("k"), color_by = "letters"))
})
