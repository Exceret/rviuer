test_that("render_plot() has a method for every supported source", {
  expect_in(
    c("render_plot.character", "render_plot.raw"),
    as.character(utils::methods("render_plot"))
  )
})

test_that("render_plot() aborts on unsupported classes", {
  expect_snapshot(error = TRUE, render_plot(1L))
  expect_snapshot(error = TRUE, render_plot(TRUE))
})

test_that("render_plot() aborts when the file does not exist", {
  expect_snapshot(error = TRUE, render_plot("does-not-exist.png"))
})

test_that("render_plot() rejects conflicting image sources", {
  path <- local_png_file()

  expect_snapshot(error = TRUE, render_plot(path, raw = png_raw()))
  expect_snapshot(error = TRUE, render_plot(png_raw(), file_path = path))
})

test_that("render_plot() forwards a file path to print_image()", {
  path <- local_png_file()
  recorded <- new.env()

  local_mocked_bindings(
    print_image = function(config, file_path = NULL, raw = NULL) {
      recorded$config <- config
      recorded$file_path <- file_path
      recorded$raw <- raw
      invisible(NULL)
    }
  )

  config <- get_viuer_config(width = 5L, height = 5L)

  expect_true(render_plot(path, config = config))
  expect_identical(recorded$config, config)
  expect_identical(recorded$file_path, path)
  expect_null(recorded$raw)
})

test_that("render_plot() forwards raw bytes to print_image()", {
  bytes <- png_raw()
  recorded <- new.env()

  local_mocked_bindings(
    print_image = function(config, file_path = NULL, raw = NULL) {
      recorded$config <- config
      recorded$file_path <- file_path
      recorded$raw <- raw
      invisible(NULL)
    }
  )

  config <- get_viuer_config(width = 5L, height = 5L)

  expect_true(render_plot(bytes, config = config))
  expect_identical(recorded$config, config)
  expect_identical(recorded$raw, bytes)
  expect_null(recorded$file_path)
})

test_that("render_plot() sends only the matching image source", {
  path <- local_png_file()
  recorded <- new.env()

  local_mocked_bindings(
    print_image = function(...) {
      recorded$args <- names(list(...))
      invisible(NULL)
    }
  )

  render_plot(path)
  expect_setequal(recorded$args, c("config", "file_path"))

  render_plot(png_raw())
  expect_setequal(recorded$args, c("config", "raw"))
})

test_that("render_plot() returns invisibly", {
  path <- local_png_file()

  local_mocked_bindings(
    print_image = function(...) invisible(NULL)
  )

  expect_invisible(render_plot(path))
  expect_invisible(render_plot(png_raw()))
})

test_that("render_plot() prints a real image", {
  path <- local_png_file(n = 2L)
  config <- half_block_config()

  streams <- capture_streams(invisible(render_plot(path, config = config)))
  expect_true(has_escape(streams$messages))

  streams <- capture_streams(invisible(render_plot(png_raw(n = 2L), config)))
  expect_true(has_escape(streams$messages))
})

test_that("render_plot() draws into the configured console stream", {
  bytes <- png_raw(n = 2L)

  streams <- capture_streams(invisible(render_plot(
    bytes,
    half_block_config(output = "stdout")
  )))
  expect_true(has_escape(streams$output))
  expect_length(streams$messages, 0)

  streams <- capture_streams(invisible(render_plot(bytes, half_block_config())))
  expect_true(has_escape(streams$messages))
  expect_length(streams$output, 0)
})
