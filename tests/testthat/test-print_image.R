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

test_that("print_image() accepts a partial configuration", {
  path <- local_png_file(n = 2L)

  expect_null(
    print_image(list(width = 1L, height = 1L), file_path = path)
  )
})

test_that("print_image() prints a PNG from memory", {
  expect_null(
    print_image(
      get_viuer_config(width = 1L, height = 1L),
      raw = png_raw(n = 2L)
    )
  )
})
