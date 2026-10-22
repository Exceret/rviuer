# draw_matrix() aborts on invalid input

    Code
      draw_matrix(1:4)
    Condition
      Error in `matrix_to_pixels()`:
      ! `m` must be a matrix.

---

    Code
      draw_matrix(get_glyph("k"), color_by = "letters")
    Condition
      Error in `draw_matrix()`:
      ! `color_by` must be one of "none" or "letter", not "letters".
      i Did you mean "letter"?

