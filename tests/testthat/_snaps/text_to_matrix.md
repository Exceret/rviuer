# text_to_matrix() aborts when `text` is not a single string

    Code
      text_to_matrix(1L)
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

---

    Code
      text_to_matrix(NULL)
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

---

    Code
      text_to_matrix(NA_character_)
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

---

    Code
      text_to_matrix(c("a", "b"))
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

# text_to_matrix() aborts on negative spacing

    Code
      text_to_matrix("a", spacing = -1L)
    Condition
      Error in `text_to_matrix()`:
      ! `spacing` and `line_spacing` must be non-negative.

---

    Code
      text_to_matrix("a", line_spacing = -1L)
    Condition
      Error in `text_to_matrix()`:
      ! `spacing` and `line_spacing` must be non-negative.

# text_to_matrix() aborts on characters the font does not define

    Code
      text_to_matrix("a~")
    Condition
      Error in `get_glyph()`:
      ! No glyph defined for "~". See `names(pixel_font_3x5)` for the available characters.

