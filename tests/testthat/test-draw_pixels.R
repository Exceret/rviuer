test_that("draw_pixels() returns a ggplot", {
  skip_if_not_installed("ggplot2")

  expect_s3_class(draw_pixels("rviuer"), "ggplot")
})

test_that("draw_pixels() draws every pixel of the text", {
  skip_if_not_installed("ggplot2")

  m <- text_to_matrix("rviuer")
  built <- ggplot2::ggplot_build(draw_pixels("rviuer"))$data[[1]]

  expect_identical(nrow(built), 115L)
  expect_identical(nrow(built), length(m))
})

test_that("draw_pixels() uses one fill colour for all the letters", {
  skip_if_not_installed("ggplot2")

  built <- ggplot2::ggplot_build(
    draw_pixels("ab", fill = "#FF0000", background = "#0000FF")
  )$data[[1]]

  expect_setequal(unique(built$fill), c("#FF0000", "#0000FF"))
})

test_that("draw_pixels() colours each letter when `color_by = 'letter'`", {
  skip_if_not_installed("ggplot2")

  m <- text_to_matrix("ab", index = TRUE)
  built <- ggplot2::ggplot_build(
    draw_pixels("ab", color_by = "letter", palette = c("red", "blue"))
  )$data[[1]]

  expect_setequal(unique(built$fill), c("white", "red", "blue"))
  expect_identical(sum(built$fill == "red"), sum(m == 1L))
})

test_that("draw_pixels() recycles a short palette", {
  skip_if_not_installed("ggplot2")

  built <- ggplot2::ggplot_build(
    draw_pixels("abc", color_by = "letter", palette = "red")
  )$data[[1]]

  expect_setequal(unique(built$fill), c("white", "red"))
})

test_that("draw_pixels() forwards the spacing arguments", {
  skip_if_not_installed("ggplot2")

  expect_identical(
    nrow(ggplot2::ggplot_build(draw_pixels("hi\nyo"))$data[[1]]),
    77L
  )
  expect_identical(
    nrow(
      ggplot2::ggplot_build(
        draw_pixels("hi\nyo", spacing = 0L, line_spacing = 0L)
      )$data[[1]]
    ),
    60L
  )
})

test_that("draw_pixels() accepts a custom font", {
  skip_if_not_installed("ggplot2")

  font <- pixel_font_add(char = "#", rows = rep("111", 5L))
  built <- ggplot2::ggplot_build(draw_pixels("#", font))$data[[1]]

  expect_identical(nrow(built), 15L)
  expect_true(all(built$fill == "steelblue"))
})

test_that("draw_pixels() drops the grid lines when `border = NA`", {
  skip_if_not_installed("ggplot2")

  built <- ggplot2::ggplot_build(draw_pixels("a", border = NA))$data[[1]]

  expect_true(all(is.na(built$colour)))
})

test_that("draw_pixels() aborts on invalid input", {
  expect_snapshot(error = TRUE, draw_pixels(1L))
  expect_snapshot(error = TRUE, draw_pixels(NA_character_))
  expect_snapshot(error = TRUE, draw_pixels("a", spacing = -1L))
  expect_snapshot(error = TRUE, draw_pixels("a", color_by = "letters"))
})
