# rviuer recipes

All snippets assume `library(rviuer)` and an R session attached to a graphics-capable terminal. Run them at the console, not through a redirected `Rscript` / CI log.

## 1. Plot to terminal, fitted to the terminal

```r
p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
capture_plot(p, width = 8, height = 5) |> render_plot()
```

Default `get_viuer_config()` leaves `width`/`height` `NULL`, so the image is fitted to the terminal with the aspect ratio preserved and the last row/column kept free.

## 2. Explicit on-screen size

```r
capture_plot(p, width = 8, height = 5) |>
  render_plot(get_viuer_config(width = 60))          # 60 columns, rows from aspect
```

```r
# fixed box, may overflow and scroll on a small terminal
capture_plot(p, width = 8, height = 5) |>
  render_plot(get_viuer_config(width = 80, height = 24))
```

Remember: config units are terminal cells, capture units are inches/pixels.

## 3. Base graphics and multi-panel layouts

```r
capture_plot(plot(1:10), width = 4, height = 3) |> render_plot()
capture_plot(hist(rnorm(100)), width = 4, height = 3) |> render_plot()

capture_plot({
  par(mfrow = c(1, 2), mar = c(4, 4, 2, 1))
  hist(rnorm(100), main = "a")
  boxplot(mpg ~ cyl, data = mtcars, main = "b")
}, width = 8, height = 3) |> render_plot()
```

Multiple pages (e.g. `par(mfrow)` redraws, or several `plot()` calls with `page()`): only the last page is returned. Capture pages separately if all are needed.

## 4. Image file or URL

```r
render_plot("logo.png")
render_plot("logo.png", config = get_viuer_config(width = 40))

url <- "https://raw.githubusercontent.com/tidyverse/dplyr/main/man/figures/logo.png"
dest <- tempfile(fileext = ".png")
download.file(url, destfile = dest, mode = "wb")   # mode = "wb" matters on Windows
render_plot(dest)
unlink(dest)
```

Any format the `image` crate decodes works from a path (PNG, JPEG, GIF, BMP, ...). Only the `raw` method is PNG-only.

## 5. Transparent images

```r
render_plot("logo.png", config = get_viuer_config(transparent = TRUE))
render_plot("logo.png", config = get_viuer_config(transparent = TRUE, premultiplied_alpha = TRUE))
```

With `transparent = FALSE` (default) semi-transparent pixels are blended onto a checkerboard pattern; with `transparent = TRUE` fully transparent pixels are left empty (the terminal background shows through) and semi-transparent pixels are drawn with their raw RGB, since ANSI cells have no alpha channel. `premultiplied_alpha` only affects that blending, so it matters mostly with `transparent = FALSE`.

## 6. Capture without printing

```r
png_bytes <- capture_plot(p, width = 8, height = 5)
writeBin(png_bytes, "plot.png")
```

Because the return value is plain PNG `raw`, it can be hashed, embedded, sent over a socket or fed to `magick::image_read()`. Prefer `ggsave()` / `ragg::agg_png()` when a file is all that is wanted — `capture_plot()` exists to avoid temporary files.

## 7. Animate or redraw in place

```r
cfg <- get_viuer_config(width = 40, restore_cursor = TRUE, absolute_offset = TRUE, x = 2, y = 1)
for (i in 1:10) {
  capture_plot(plot(i, i, xlim = c(1, 10), ylim = c(1, 10), cex = 3)) |>
    render_plot(cfg)
  Sys.sleep(0.2)
}
```

`restore_cursor = TRUE` puts the cursor back after printing so the next image lands on top of the previous one. With `absolute_offset = TRUE` the `x`/`y` offsets are counted from the terminal's top-left corner instead of the cursor.

## 8. Pixel-art banner, then show it

```r
draw_pixels("rviuer", color_by = "letter") |>
  capture_plot(width = 6, height = 2) |>
  render_plot(get_viuer_config(width = 40))

# save instead of render
ggplot2::ggsave("banner.png", draw_pixels("RVIUER"), width = 6, height = 2, dpi = 150)
```

Custom characters, custom palette:

```r
font <- pixel_font_add(pixel_font_3x5, "#", c("101", "111", "101", "111", "101"))
draw_pixels("C#", font = font, palette = c("tomato", "steelblue"))
```

## 9. Non-interactive / CI sessions

Half-block escape sequences end up in the log stream, so guard rendering:

```r
if (interactive() && isatty(stdout())) {
  capture_plot(p) |> render_plot()
} else {
  ggplot2::ggsave("plot.png", p, width = 8, height = 5, dpi = 150)
}
```

`rviuer:::terminal_size()` returns `80 x 24` when stdout is not a terminal, so an apparently "wrong" size is usually a sign that no TTY was attached.

## 10. Diagnose a bad result

```r
rviuer:::terminal_size()                     # what the package thinks the terminal is
rviuer:::fit_terminal_cells(1600, 900, 80, 24)  # c(79, 22): cells for a 16:9 image
Sys.getenv(c("TERM", "TERM_PROGRAM", "LC_TERMINAL", "COLORTERM", "KITTY_WINDOW_ID"))
isatty(stdout())
```

Symptom → likely cause:

| Symptom | Cause |
| --- | --- |
| Garbled colour blocks / escape soup in a log file | no graphics terminal, half-block fallback written to a pipe |
| Image wider/taller than expected | config `width`/`height` given in cells, or both unset and the terminal reports `80 x 24` (no TTY) |
| Image squeezed vertically | both config dimensions set to a non-aspect box; set only one and let the other follow |
| `Plot height is reset to max height` warning | image too tall after width fitting, shrunk to terminal height |
| Nothing appears in RStudio/Positron Console | the IDE console is not a graphics terminal — open the system terminal |
| Colours look 256-colour | `COLORTERM` does not contain `truecolor`/`24bit`, or `truecolor = FALSE` |
