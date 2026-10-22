test_that("pixel_font_3x5 is a named list of glyphs", {
  expect_type(pixel_font_3x5, "list")
  expect_length(pixel_font_3x5, 43L)
  expect_false(anyDuplicated(names(pixel_font_3x5)) > 0L)
  expect_identical(names(pixel_font_3x5), toupper(names(pixel_font_3x5)))
})

test_that("pixel_font_3x5 covers letters, digits and punctuation", {
  expect_in(LETTERS, names(pixel_font_3x5))
  expect_in(as.character(0:9), names(pixel_font_3x5))
  expect_in(c(" ", ".", ",", "-", ":", "!", "?"), names(pixel_font_3x5))
})

test_that("every glyph is 5 rows of 3 pixels", {
  for (nm in names(pixel_font_3x5)) {
    rows <- pixel_font_3x5[[nm]]

    expect_type(rows, "character")
    expect_length(rows, 5L)
    expect_true(all(nchar(rows) == 3L))
    expect_true(all(grepl("^[01]{3}$", rows)))
  }
})

test_that("every glyph passes check_glyph()", {
  for (nm in names(pixel_font_3x5)) {
    expect_true(check_glyph(pixel_font_3x5[[nm]]))
  }
})

test_that("pixel_font_3x5 uses 1 for filled and 0 for empty pixels", {
  expect_true(any(grepl("1", unlist(pixel_font_3x5, use.names = FALSE))))
  expect_false(any(grepl("[^01]", unlist(pixel_font_3x5, use.names = FALSE))))

  # The space is the only fully empty glyph of the font.
  expect_identical(pixel_font_3x5[[" "]], rep("000", 5L))
})
