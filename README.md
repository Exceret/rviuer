<!-- README.md is generated from README.Rmd. Please edit that file -->

# rviuer

<!-- badges: start -->

[![Lifecycle:experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN-status](https://www.r-pkg.org/badges/version/rviuer)](https://CRAN.R-project.org/package=rviuer)
[![extendr](https://img.shields.io/badge/extendr-%5E0.9.0-276DC2)](https://extendr.github.io/extendr/extendr_api/)
[![Codecov test
coverage](https://codecov.io/gh/Exceret/rviuer/graph/badge.svg)](https://app.codecov.io/gh/Exceret/rviuer)
[![R-CMD-check](https://github.com/Exceret/rviuer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Exceret/rviuer/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of rviuer is to provide a tool to show the plot in R session
(and to practice my Rust coding 🦀).

## Installation

You can install the development version of rviuer from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("Exceret/rviuer")
```

## Usage

The package works in two steps: `capture_plot()` turns plotting code
into PNG bytes, and `render_plot()` prints those bytes (or an image
file) in the terminal.

``` r
library(rviuer)

p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
capture_plot(p, width = 6, height = 4) |> render_plot()
```

`capture_plot()` evaluates the plotting code on an in-memory `ragg`
device, so no temporary file is created; a visible return value is
printed automatically, which is why a `ggplot` object can be passed
directly. Base graphics draw on the device as usual, and any output
format works:

``` r
capture_plot(plot(1:10), width = 4, height = 3) |> render_plot()

capture_plot(
  {
    par(mfrow = c(1, 2))
    hist(rnorm(100))
    boxplot(mpg ~ cyl, data = mtcars)
  },
  width = 8,
  height = 3
) |>
  render_plot()
```

### Render an image file

`render_plot()` also accepts a path, and any format the `image` crate
can decode is fine.

``` r
url <- "https://raw.githubusercontent.com/tidyverse/dplyr/main/man/figures/logo.png"
dest <- file.path(tempdir(), "logo.png")

download.file(url, destfile = dest, mode = "wb")
render_plot(dest)
```

### Control the size

Two independent sizes are involved, and confusing them is the usual
surprise:

- `capture_plot(width, height, units, res)` sets the physical size of
  the captured PNG (inches, cm, mm or px).
- `get_viuer_config(width, height)` sets how many **terminal cells** the
  image occupies.

``` r
# sharp image, 60 columns wide on screen
capture_plot(p, width = 8, height = 5) |>
  render_plot(get_viuer_config(width = 60))
```

When both config dimensions are `NULL` (the default) the image is fitted
to the terminal, keeping the aspect ratio and never scaling a small
image up. Setting only one of them lets the other follow from the aspect
ratio.

### Other options

`get_viuer_config()` collects the printing options: size, offsets (`x`,
`y`, `absolute_offset`), `transparent` and `premultiplied_alpha` for
images with alpha, `restore_cursor` for redrawing in place, and
`truecolor`, `use_iterm`, `use_kitty`, `use_sixel` to allow or forbid a
graphics protocol.

``` r
render_plot(
  "logo.png",
  config = get_viuer_config(width = 40, transparent = TRUE)
)
```

### Pixel art text

`draw_pixels()` renders text with the built-in 3 x 5 font and returns a
`ggplot` object, so it can be extended or saved like any other plot.

``` r
draw_pixels("rviuer") |>
  capture_plot(width = 6, height = 2) |>
  render_plot()
```

The font covers `A`-`Z`, `0`-`9`, the space and a few punctuation marks;
missing characters can be added with `pixel_font_add()`.
`text_to_matrix()` and `matrix_to_pixels()` expose the underlying pixel
grid.

``` r
font <- pixel_font_add(
  pixel_font_3x5,
  "#",
  c("101", "111", "101", "111", "101")
)
draw_pixels("C#", font = font, palette = c("tomato", "steelblue"))
```

### Where images can be shown

The graphics protocol is chosen automatically: iTerm, Kitty or Sixel
when the terminal supports it, coloured half-blocks otherwise. A real
terminal is required — RStudio, Positron and other IDE consoles,
`Rscript` with redirected output and CI logs only receive the fallback’s
escape sequences. Use `isatty(stderr())` (or `interactive()`) to guard
rendering code in scripts.

Images are drawn on R’s message stream (stderr), the way the cli package
writes its messages: `sink()` and `capture.output()` leave them alone,
while `sink(type = "message")` and `capture.output(type = "message")`
capture or silence them. Pass `output = "stdout"` to
`get_viuer_config()` to draw on the ordinary output stream instead.

## Agent skill

The repository ships an agent skill in `skills/rviuer/`, so coding
assistants (Claude Code, Codex, CodeBuddy, …) know how to drive the
package: the capture/render pipeline, the difference between a capture
size and a terminal-cell size, which protocol the current terminal gets,
and the error messages worth recognising. It also bundles
`skills/rviuer/scripts/check_terminal.R`, which reports the detected
protocol, the terminal size and an optional test render.

Install it with the `skills` CLI:

``` bash
npx skills add Exceret/rviuer --skill rviuer
```

From a local clone the same command works with the path instead of the
repository name:

``` bash
npx skills add . --skill rviuer
```

Add `--list` to only show the skills a repository offers, `--global` to
install at user level instead of project level, and `--copy` to copy the
files rather than symlink them into the agent directory.

## Acknowledgements

This project is derived from [viuer](https://github.com/atanunq/viuer)
by [@atanunq](https://github.com/atanunq). Many thanks to the original
author and all contributors for their open-source work.

- viuer is released under the [MIT
  License](inst/vendor/viuer/LICENSE-MIT). The original copyright notice
  and full license text are preserved unchanged in `LICENSE-MIT`; please
  do not remove it.
- The parts modified are released under the MIT License. See
  [LICENSE](LICENSE) for details.
- This project is not affiliated with or endorsed by the original viuer
  author, who is not responsible for the modifications made here.
- This software is provided “as is”, without warranty of any kind,
  express or implied. Use it at your own risk.
