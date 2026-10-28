test_that("print_image() requires exactly one image source", {
  expect_snapshot(error = TRUE, print_image(get_viuer_config()))

  path <- local_png_file()
  expect_snapshot(
    error = TRUE,
    print_image(get_viuer_config(), file_path = path, raw = png_raw())
  )
})

test_that("print_image() aborts on undecodable bytes", {
  expect_snapshot(
    error = TRUE,
    print_image(get_viuer_config(), raw = charToRaw("not a png"))
  )
})

test_that("print_image() reports printing failures", {
  # The tail of the IO error is produced by the OS and differs between
  # platforms (Windows: "The system cannot find the file specified."), so it is
  # scrubbed before the snapshot comparison.
  scrub_io_error <- function(lines) {
    sub("(IO error:).*", "\\1 <os message>", lines)
  }

  expect_snapshot(
    error = TRUE,
    print_image(get_viuer_config(), file_path = "missing.png"),
    transform = scrub_io_error
  )
})

test_that("print_image() validates the configuration", {
  path <- local_png_file()

  expect_snapshot(error = TRUE, print_image(list(x = -1L), file_path = path))
  expect_snapshot(error = TRUE, print_image(list(y = 40000L), file_path = path))
  expect_snapshot(
    error = TRUE,
    print_image(list(width = -1L), file_path = path)
  )
  expect_snapshot(error = TRUE, print_image(list(x = 1.5), file_path = path))
  expect_snapshot(
    error = TRUE,
    print_image(list(transparent = "yes"), file_path = path)
  )
})

test_that("print_image() validates the output channel", {
  expect_snapshot(
    error = TRUE,
    print_image(half_block_config(), raw = png_raw(2L), output = "console")
  )
  expect_snapshot(
    error = TRUE,
    print_image(list(output = "console"), raw = png_raw(2L))
  )
  expect_snapshot(
    error = TRUE,
    print_image(list(output = TRUE), raw = png_raw(2L))
  )
})

test_that("print_image() accepts a partial configuration", {
  path <- local_png_file(n = 2L)

  streams <- capture_streams(
    invisible(print_image(list(width = 1L, height = 1L), file_path = path))
  )

  expect_true(has_escape(streams$messages))
})

test_that("print_image() prints a PNG from memory", {
  streams <- capture_streams(invisible(print_image(
    half_block_config(),
    raw = png_raw(n = 2L)
  )))

  expect_true(has_escape(streams$messages))
})

test_that("print_image() draws into R's message stream by default", {
  streams <- capture_streams(invisible(print_image(
    half_block_config(),
    raw = png_raw(n = 2L)
  )))

  # The picture is on stderr, R's ordinary output stays clean: `sink()` and
  # `capture.output()` no longer swallow or capture the image.
  expect_length(streams$output, 0)
  expect_true(has_escape(streams$messages))
})

test_that("print_image() draws into R's output stream on request", {
  streams <- capture_streams(invisible(print_image(
    half_block_config(output = "stdout"),
    raw = png_raw(n = 2L)
  )))

  expect_true(has_escape(streams$output))
  expect_length(streams$messages, 0)
})

test_that("print_image() lets the output argument win over the configuration", {
  streams <- capture_streams(invisible(print_image(
    half_block_config(output = "stderr"),
    raw = png_raw(n = 2L),
    output = "stdout"
  )))

  expect_true(has_escape(streams$output))
  expect_length(streams$messages, 0)
})

test_that("print_image() prints a file to the message stream", {
  path <- local_png_file(n = 2L)

  streams <- capture_streams(invisible(print_image(
    half_block_config(),
    file_path = path
  )))

  expect_true(has_escape(streams$messages))
})
