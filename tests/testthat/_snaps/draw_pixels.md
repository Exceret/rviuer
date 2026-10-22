# draw_pixels() aborts on invalid input

    Code
      draw_pixels(1L)
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

---

    Code
      draw_pixels(NA_character_)
    Condition
      Error in `text_to_matrix()`:
      ! `text` must be a single string.

---

    Code
      draw_pixels("a", spacing = -1L)
    Condition
      Error in `text_to_matrix()`:
      ! `spacing` and `line_spacing` must be non-negative.

---

    Code
      draw_pixels("a", color_by = "letters")
    Condition
      Error in `draw_pixels()`:
      ! `color_by` must be one of "none" or "letter", not "letters".
      i Did you mean "letter"?

