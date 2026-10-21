# capture_plot() aborts when nothing is drawn

    Code
      capture_plot(invisible(NULL))
    Condition
      Error in `capture_plot()`:
      x Nothing was drawn by `expr`.

# capture_plot() validates its arguments

    Code
      capture_plot(plot(1:10), units = "inches")
    Condition
      Error in `capture_plot()`:
      ! `units` must be one of "in", "cm", "mm", or "px", not "inches".

---

    Code
      capture_plot(plot(1:10), width = 7.5)
    Condition
      Error in `capture_plot()`:
      ! `width` must be a whole number, not the number 7.5.

---

    Code
      capture_plot(plot(1:10), height = 7.5)
    Condition
      Error in `capture_plot()`:
      ! `height` must be a whole number, not the number 7.5.

---

    Code
      capture_plot(plot(1:10), res = 96.5)
    Condition
      Error in `capture_plot()`:
      ! `res` must be a whole number, not the number 96.5.

