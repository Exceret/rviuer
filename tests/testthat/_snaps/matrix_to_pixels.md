# matrix_to_pixels() aborts when `m` is not a matrix

    Code
      matrix_to_pixels(1:4)
    Condition
      Error in `matrix_to_pixels()`:
      ! `m` must be a matrix.

---

    Code
      matrix_to_pixels(data.frame(a = 1))
    Condition
      Error in `matrix_to_pixels()`:
      ! `m` must be a matrix.

---

    Code
      matrix_to_pixels(NULL)
    Condition
      Error in `matrix_to_pixels()`:
      ! `m` must be a matrix.

