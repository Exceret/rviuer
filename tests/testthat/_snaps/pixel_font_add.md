# pixel_font_add() aborts when `char` is not a single character

    Code
      pixel_font_add(char = 1L, rows = rows)
    Condition
      Error in `pixel_font_add()`:
      ! `char` must be a single character.

---

    Code
      pixel_font_add(char = NA_character_, rows = rows)
    Condition
      Error in `pixel_font_add()`:
      ! `char` must be a single character.

---

    Code
      pixel_font_add(char = c("a", "b"), rows = rows)
    Condition
      Error in `pixel_font_add()`:
      ! `char` must be a single character.

---

    Code
      pixel_font_add(char = "ab", rows = rows)
    Condition
      Error in `pixel_font_add()`:
      ! `char` must be a single character.

# pixel_font_add() aborts when `rows` is not a valid glyph

    Code
      pixel_font_add(char = "#", rows = "101")
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

---

    Code
      pixel_font_add(char = "#", rows = 1:5)
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

---

    Code
      pixel_font_add(char = "#", rows = c("101", "101", "101", "101"))
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

---

    Code
      pixel_font_add(char = "#", rows = c("101", "101", "101", "101", "102"))
    Condition
      Error in `check_glyph()`:
      ! A glyph must be a character vector of 5 strings, each made of exactly "3" characters from "0" and "1".

