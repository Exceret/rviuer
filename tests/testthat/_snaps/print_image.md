# print_image() requires exactly one image source

    Code
      print_image(get_viuer_config())
    Condition
      Error in `print_image()`:
      ! supply either `file_path` or `raw`

---

    Code
      print_image(get_viuer_config(), file_path = path, raw = png_raw())
    Condition
      Error in `print_image()`:
      ! supply only one of `file_path` and `raw`

# print_image() aborts on undecodable bytes

    Code
      print_image(get_viuer_config(), raw = charToRaw("not a png"))
    Condition
      Error in `print_image()`:
      ! Image decoding failed: Format error decoding Png: Invalid PNG signature.

# print_image() reports printing failures

    Code
      print_image(get_viuer_config(), file_path = "missing.png")
    Condition
      Error in `print_image()`:
      ! Image printing failed: IO error: No such file or directory (os error 2)

# print_image() validates the configuration

    Code
      print_image(list(x = -1L), file_path = path)
    Condition
      Error in `print_image()`:
      ! `x` must be a whole number in [0, 65535]

---

    Code
      print_image(list(y = 40000L), file_path = path)
    Condition
      Error in `print_image()`:
      ! `y` must be a whole number in [-32768, 32767]

---

    Code
      print_image(list(width = -1L), file_path = path)
    Condition
      Error in `print_image()`:
      ! `width` must be a whole number in [0, 4294967295]

---

    Code
      print_image(list(x = 1.5), file_path = path)
    Condition
      Error in `print_image()`:
      ! `x` must be a single whole number

---

    Code
      print_image(list(transparent = "yes"), file_path = path)
    Condition
      Error in `print_image()`:
      ! `transparent` must be TRUE or FALSE

