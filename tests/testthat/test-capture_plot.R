test_that("capture_plot() returns a PNG raw vector", {
  bytes <- capture_plot(plot(1:10))

  expect_type(bytes, "raw")
  expect_gt(length(bytes), 0)
  expect_identical(rawToChar(bytes[2:4]), "PNG")
})

test_that("capture_plot() accepts a braced block", {
  bytes <- capture_plot({
    par(mfrow = c(1, 2))
    hist(rnorm(100))
    boxplot(mpg ~ cyl, data = mtcars)
  })

  expect_type(bytes, "raw")
  expect_identical(rawToChar(bytes[2:4]), "PNG")
})

test_that("capture_plot() prints visible results", {
  skip_if_not_installed("ggplot2")

  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  bytes <- capture_plot(plot)

  expect_type(bytes, "raw")
  expect_identical(rawToChar(bytes[2:4]), "PNG")
})

test_that("capture_plot() honours the image arguments", {
  small <- capture_plot(plot(1:10), width = 2L, height = 2L)
  large <- capture_plot(plot(1:10), width = 8L, height = 8L)

  expect_gt(length(large), length(small))

  expect_type(capture_plot(plot(1:10), units = "cm"), "raw")
  expect_type(capture_plot(plot(1:10), res = 150L), "raw")
  expect_type(capture_plot(plot(1:10), bg = "grey90"), "raw")
  expect_type(capture_plot(plot(1:10), pointsize = 10), "raw")
})

test_that("capture_plot() accepts fractional sizes", {
  bytes <- capture_plot(plot(1:10), width = 7.5, height = 7.5)

  expect_type(bytes, "raw")
  expect_identical(rawToChar(bytes[2:4]), "PNG")

  # Fractional sizes are honoured rather than rounded to whole numbers.
  dims <- dim(png::readPNG(capture_plot(
    plot(1:10),
    width = 2.5,
    height = 2.25,
    res = 96L
  )))
  expect_identical(dims[2], 240L)
  expect_identical(dims[1], 216L)

  expect_type(capture_plot(plot(1:10), width = 3.25, units = "cm"), "raw")
  expect_type(
    capture_plot(plot(1:10), width = 50.5, height = 50.5, units = "mm"),
    "raw"
  )
})

test_that("capture_plot() aborts when nothing is drawn", {
  expect_snapshot(error = TRUE, capture_plot(invisible(NULL)))
})

test_that("capture_plot() validates its arguments", {
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), units = "inches"))
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), res = 96.5))

  expect_snapshot(error = TRUE, capture_plot(plot(1:10), width = "7"))
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), height = "7"))
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), width = NULL))
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), height = NULL))
  expect_snapshot(error = TRUE, capture_plot(plot(1:10), width = c(1, 2)))
})

test_that("capture_plot() closes the capture device", {
  before <- grDevices::dev.cur()

  capture_plot(plot(1:10))
  expect_identical(grDevices::dev.cur(), before)

  try(capture_plot(invisible(NULL)), silent = TRUE)
  expect_identical(grDevices::dev.cur(), before)
})
