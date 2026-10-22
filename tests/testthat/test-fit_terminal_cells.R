test_that("fit_terminal_cells() fits a wide image to the width", {
  # the 10 x 3 in capture at 96 dpi, printed in an 80 x 24 terminal
  cells <- fit_terminal_cells(960L, 288L, 80L, 24L)

  expect_identical(cells, c(79L, 12L))
})

test_that("fit_terminal_cells() fits a tall image to the height", {
  # 3 x 10 in capture, same terminal
  expect_identical(fit_terminal_cells(288L, 960L, 80L, 24L), c(14L, 23L))
})

test_that("fit_terminal_cells() fits a square image to the height", {
  # the 7 x 7 in capture (672 x 672 px): height bound, width follows
  expect_identical(fit_terminal_cells(672L, 672L, 80L, 24L), c(46L, 23L))
})

test_that("fit_terminal_cells() keeps the last row and column free", {
  terminals <- list(c(80L, 24L), c(1L, 1L), c(120L, 30L), c(999L, 2L))
  images <- list(c(960L, 288L), c(672L, 672L), c(288L, 960L), c(1L, 1L))

  for (term in terminals) {
    for (img in images) {
      cells <- fit_terminal_cells(img[1], img[2], term[1], term[2])

      expect_lte(cells[1], max(term[1] - 1L, 1L))
      expect_lte(cells[2], max(term[2] - 1L, 1L))
      expect_gte(cells[1], 1L)
      expect_gte(cells[2], 1L)
    }
  }
})

test_that("fit_terminal_cells() does not blow up images that already fit", {
  expect_identical(fit_terminal_cells(4L, 3L, 80L, 24L), c(4L, 2L))
  expect_identical(fit_terminal_cells(79L, 46L, 80L, 24L), c(79L, 23L))
})

test_that("fit_terminal_cells() keeps the aspect ratio to within a cell", {
  terminals <- list(c(80L, 24L), c(100L, 30L), c(200L, 50L), c(60L, 20L))
  images <- list(c(960L, 288L), c(672L, 672L), c(288L, 960L), c(1600L, 900L))

  for (term in terminals) {
    for (img in images) {
      cells <- fit_terminal_cells(img[1], img[2], term[1], term[2])
      # a cell holds two image rows, so the printed aspect is 2 * h / w
      printed <- 2 * cells[2] / cells[1]
      source <- img[2] / img[1]

      expect_lt(abs(printed - source) / source, 0.05)
    }
  }
})

test_that("fit_terminal_cells() handles degenerate sizes", {
  expect_identical(fit_terminal_cells(0L, 0L, 80L, 24L), c(1L, 1L))
  expect_identical(fit_terminal_cells(960L, 288L, 1L, 1L), c(1L, 1L))
})

test_that("terminal_size() reports both dimensions", {
  size <- terminal_size()

  expect_type(size, "list")
  expect_named(size, c("width", "height"))
  expect_true(all(vapply(size, rlang::is_integerish, logical(1))))
  expect_true(size$width >= 1)
  expect_true(size$height >= 1)
})
