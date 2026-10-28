test_that("get_viuer_config() returns the documented defaults", {
  config <- get_viuer_config()

  expect_type(config, "list")
  expect_named(
    config,
    c(
      "transparent",
      "premultiplied_alpha",
      "absolute_offset",
      "x",
      "y",
      "restore_cursor",
      "width",
      "height",
      "truecolor",
      "use_kitty",
      "use_iterm",
      "use_sixel",
      "output"
    )
  )
  expect_false(config$transparent)
  expect_false(config$premultiplied_alpha)
  expect_false(config$absolute_offset)
  expect_identical(config$x, 0L)
  expect_identical(config$y, 0L)
  expect_false(config$restore_cursor)
  expect_null(config$width)
  expect_null(config$height)
  expect_true(config$truecolor)
  expect_true(config$use_kitty)
  expect_true(config$use_iterm)
  expect_true(config$use_sixel)
  expect_identical(config$output, "stderr")
})

test_that("get_viuer_config() keeps the values it is given", {
  config <- get_viuer_config(
    transparent = TRUE,
    premultiplied_alpha = TRUE,
    absolute_offset = FALSE,
    x = 2L,
    y = -3L,
    restore_cursor = TRUE,
    width = 40L,
    height = 20L,
    truecolor = FALSE,
    use_kitty = FALSE,
    use_iterm = FALSE,
    use_sixel = FALSE,
    output = "stdout"
  )

  expect_true(config$transparent)
  expect_true(config$premultiplied_alpha)
  expect_false(config$absolute_offset)
  expect_identical(config$x, 2L)
  expect_identical(config$y, -3L)
  expect_true(config$restore_cursor)
  expect_identical(config$width, 40L)
  expect_identical(config$height, 20L)
  expect_false(config$truecolor)
  expect_false(config$use_kitty)
  expect_false(config$use_iterm)
  expect_false(config$use_sixel)
  expect_identical(config$output, "stdout")
})

test_that("get_viuer_config() accepts whole doubles", {
  config <- get_viuer_config(x = 3, y = 4, width = 10, height = 8)

  expect_identical(config$x, 3)
  expect_identical(config$width, 10)
})

test_that("get_viuer_config() checks logical options", {
  expect_snapshot(error = TRUE, get_viuer_config(transparent = "yes"))
  expect_snapshot(error = TRUE, get_viuer_config(premultiplied_alpha = 1))
  expect_snapshot(error = TRUE, get_viuer_config(absolute_offset = NA))
  expect_snapshot(error = TRUE, get_viuer_config(restore_cursor = NULL))
  expect_snapshot(error = TRUE, get_viuer_config(truecolor = c(TRUE, FALSE)))
  expect_snapshot(error = TRUE, get_viuer_config(use_kitty = "TRUE"))
  expect_snapshot(error = TRUE, get_viuer_config(use_iterm = 0))
  expect_snapshot(error = TRUE, get_viuer_config(use_sixel = list()))
})

test_that("get_viuer_config() checks offsets", {
  expect_snapshot(error = TRUE, get_viuer_config(x = 1.5))
  expect_snapshot(error = TRUE, get_viuer_config(x = NULL))
  expect_snapshot(error = TRUE, get_viuer_config(y = 1.5))
  expect_snapshot(error = TRUE, get_viuer_config(y = NULL))
  expect_snapshot(error = TRUE, get_viuer_config(x = "0"))
})

test_that("get_viuer_config() checks dimensions", {
  expect_snapshot(error = TRUE, get_viuer_config(width = 1.5))
  expect_snapshot(error = TRUE, get_viuer_config(width = "40"))
  expect_snapshot(error = TRUE, get_viuer_config(height = 1.5))
  expect_snapshot(error = TRUE, get_viuer_config(height = "20"))
})

test_that("get_viuer_config() checks the output channel", {
  expect_snapshot(error = TRUE, get_viuer_config(output = "console"))
  expect_snapshot(error = TRUE, get_viuer_config(output = "STDERR"))
  expect_snapshot(error = TRUE, get_viuer_config(output = NULL))
})
