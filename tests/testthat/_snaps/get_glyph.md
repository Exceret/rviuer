# get_glyph() aborts when `char` is not a single character

    Code
      get_glyph(1L)
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph(NULL)
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph(factor("a"))
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph(NA_character_)
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph(c("a", "b"))
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph("")
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

---

    Code
      get_glyph("ab")
    Condition
      Error in `get_glyph()`:
      ! `char` must be a single character.

# get_glyph() aborts on characters the font does not define

    Code
      get_glyph("~")
    Condition
      Error in `get_glyph()`:
      ! No glyph defined for "~". See `names(pixel_font_3x5)` for the available characters.

---

    Code
      get_glyph("x", font = list(A = pixel_font_3x5[["A"]]))
    Condition
      Error in `get_glyph()`:
      ! No glyph defined for "x". See `names(pixel_font_3x5)` for the available characters.

# get_glyph() validates the glyph stored in the font

    Code
      get_glyph("A", font = list(A = "010"))
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

---

    Code
      get_glyph("A", font = list(A = c("010", "101", "111", "101", "102")))
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

---

    Code
      get_glyph("A", font = list(A = 1:5))
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

