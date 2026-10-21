# get_viuer_config() checks logical options

    Code
      get_viuer_config(transparent = "yes")
    Condition
      Error in `get_viuer_config()`:
      ! `transparent` must be `TRUE` or `FALSE`, not the string "yes".

---

    Code
      get_viuer_config(premultiplied_alpha = 1)
    Condition
      Error in `get_viuer_config()`:
      ! `premultiplied_alpha` must be `TRUE` or `FALSE`, not the number 1.

---

    Code
      get_viuer_config(absolute_offset = NA)
    Condition
      Error in `get_viuer_config()`:
      ! `absolute_offset` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      get_viuer_config(restore_cursor = NULL)
    Condition
      Error in `get_viuer_config()`:
      ! `restore_cursor` must be `TRUE` or `FALSE`, not `NULL`.

---

    Code
      get_viuer_config(truecolor = c(TRUE, FALSE))
    Condition
      Error in `get_viuer_config()`:
      ! `truecolor` must be `TRUE` or `FALSE`, not a logical vector.

---

    Code
      get_viuer_config(use_kitty = "TRUE")
    Condition
      Error in `get_viuer_config()`:
      ! `use_kitty` must be `TRUE` or `FALSE`, not the string "TRUE".

---

    Code
      get_viuer_config(use_iterm = 0)
    Condition
      Error in `get_viuer_config()`:
      ! `use_iterm` must be `TRUE` or `FALSE`, not the number 0.

---

    Code
      get_viuer_config(use_sixel = list())
    Condition
      Error in `get_viuer_config()`:
      ! `use_sixel` must be `TRUE` or `FALSE`, not an empty list.

# get_viuer_config() checks offsets

    Code
      get_viuer_config(x = 1.5)
    Condition
      Error in `get_viuer_config()`:
      ! `x` must be a whole number, not the number 1.5.

---

    Code
      get_viuer_config(x = NULL)
    Condition
      Error in `get_viuer_config()`:
      ! `x` must be a whole number, not `NULL`.

---

    Code
      get_viuer_config(y = 1.5)
    Condition
      Error in `get_viuer_config()`:
      ! `y` must be a whole number, not the number 1.5.

---

    Code
      get_viuer_config(y = NULL)
    Condition
      Error in `get_viuer_config()`:
      ! `y` must be a whole number, not `NULL`.

---

    Code
      get_viuer_config(x = "0")
    Condition
      Error in `get_viuer_config()`:
      ! `x` must be a whole number, not the string "0".

# get_viuer_config() checks dimensions

    Code
      get_viuer_config(width = 1.5)
    Condition
      Error in `get_viuer_config()`:
      ! `width` must be a whole number, not the number 1.5.

---

    Code
      get_viuer_config(width = "40")
    Condition
      Error in `get_viuer_config()`:
      ! `width` must be a whole number, not the string "40".

---

    Code
      get_viuer_config(height = 1.5)
    Condition
      Error in `get_viuer_config()`:
      ! `height` must be a whole number, not the number 1.5.

---

    Code
      get_viuer_config(height = "20")
    Condition
      Error in `get_viuer_config()`:
      ! `height` must be a whole number, not the string "20".

