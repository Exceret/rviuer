# render_plot() aborts on unsupported classes

    Code
      render_plot(1L)
    Condition
      Error in `render_plot()`:
      x Class <1> is not supported
      i Available classes: <character/default/raw>

---

    Code
      render_plot(TRUE)
    Condition
      Error in `render_plot()`:
      x Class <TRUE> is not supported
      i Available classes: <character/default/raw>

# render_plot() aborts when the file does not exist

    Code
      render_plot("does-not-exist.png")
    Condition
      Error in `render_plot()`:
      x 'does-not-exist.png' not exist

# render_plot() rejects conflicting image sources

    Code
      render_plot(path, raw = png_raw())
    Condition
      Error in `render_plot()`:
      x `raw` should not be provided when rendering plot from file

---

    Code
      render_plot(png_raw(), file_path = path)
    Condition
      Error in `render_plot()`:
      x `file_path` should not be provided when rendering plot from R

