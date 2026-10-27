---
name: rviuer
description: Draw images, R plots and pixel-art text directly in the terminal with the rviuer R package (iTerm, Kitty, Sixel protocols, coloured half-block fallback). This skill should be used when a user wants to show a ggplot or base plot inside an R console, render a PNG file or URL in the terminal, capture a plot as PNG bytes without temporary files, or render 3x5 pixel-letter banners in R.
license: MIT
---

# rviuer

rviuer renders images in a terminal from R. It wraps the Rust `viuer` crate through extendr and picks a graphics protocol based on the terminal, falling back to coloured half-blocks when none is available.

## When to use this skill

- Show a `ggplot2` or base graphics plot in an R console / terminal.
- Render an image file (PNG, JPEG, GIF, ...) or a downloaded logo in the terminal.
- Turn plotting code into PNG bytes with no temporary file (e.g. to embed, hash or pass on).
- Draw 3x5 pixel-font text (`draw_pixels()`) or convert text to a pixel grid.
- Diagnose why terminal output looks wrong (protocol, size, non-TTY) — see `references/terminal-support.md`.

Do not use rviuer for figures that must end up in HTML/PDF (knitr, pkgdown, RStudio Viewer): it writes escape sequences to the console stream, which those renderers do not turn into images. Use regular chunk figures, `ggsave()` or `ragg` devices there.

## Install

```r
pak::pak("Exceret/rviuer")        # GitHub, the only source today
```

Check `getNamespaceExports("rviuer")` when unsure which helpers your build has; see the version caveat in `references/api.md`.

Building from source needs a Rust toolchain: `cargo`, `rustc >= 1.65` and `xz` (`SystemRequirements` in DESCRIPTION). Without them installation fails at the `configure`/`cargo build` step.

## Core model: capture, then render

The package is a two-step pipeline; keep the two size concepts apart.

```r
library(rviuer)

# 1. capture: run plotting code on an in-memory ragg device -> PNG raw vector
png_bytes <- capture_plot(
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(),
  width = 6,
  height = 4
)

# 2. render: print those bytes in the terminal
render_plot(png_bytes)
```

Or in one chain, and from a file:

```r
capture_plot(plot(1:10), width = 4, height = 3) |> render_plot()
render_plot("logo.png")
```

- `capture_plot(expr, ...)` evaluates `expr` with the device already open. A visible return value is auto-printed like at the console, so a ggplot object can be passed directly; base graphics draw onto the device. It returns a `raw` vector of PNG bytes, never a file, and only the last page of a multi-page plot.
- `render_plot(x, config = get_viuer_config(), ...)` is an S3 generic:
  - `character` — path to an existing image file, read from disk.
  - `raw` — PNG-encoded bytes (e.g. from `capture_plot()`); the format is **not** sniffed, so non-PNG bytes fail.
  - anything else aborts with `Class <...> is not supported`.
  - Returns `TRUE` invisibly.

## Sizing: two independent knobs

| Knob | Unit | Controls |
| --- | --- | --- |
| `capture_plot(width, height, units, res)` | inches / cm / mm / px | pixel resolution and aspect of the captured PNG |
| `get_viuer_config(width, height)` | **terminal cells** | how many columns/rows the image occupies on screen |

Rules implemented in the package:

- Both config dimensions `NULL` (default): the image is fitted to the terminal, keeping one row and one column free, aspect ratio preserved. Small images are not blown up.
- Only one dimension set: the other follows from the image aspect ratio (`viuer` computes it).
- Both set: exact size, even if it overflows the terminal and scrolls.
- One cell is about twice as tall as it is wide, so N pixel rows occupy about N/2 cell rows.
- If a width-fitted image is still taller than the terminal it is shrunk to the terminal height and warns `Plot height is reset to max height`.

So: change `capture_plot()` size to change detail/sharpness; change the config size to change how large it appears.

## Configuration options (`get_viuer_config()`)

All arguments are validated; unknown terminals simply ignore the protocol switches.

| Argument | Default | Use |
| --- | --- | --- |
| `width`, `height` | `NULL` | size in terminal cells; `NULL` = fit terminal |
| `x`, `y` | `0L` | offset; `x` must be `>= 0`, `y` may be negative when `absolute_offset = FALSE` |
| `absolute_offset` | `FALSE` | `TRUE` = offsets from the terminal's top-left, `FALSE` = `y` from the cursor |
| `transparent` | `FALSE` | `TRUE` leaves fully transparent pixels empty (terminal background shows) instead of drawing the checkerboard |
| `premultiplied_alpha` | `FALSE` | alpha channel is already premultiplied |
| `restore_cursor` | `FALSE` | put the cursor back after printing, for in-place redraws/animations |
| `truecolor` | `TRUE` | 24-bit colour when the terminal supports it (`COLORTERM`) |
| `use_iterm` | `TRUE` | allow iTerm protocol |
| `use_kitty` | `TRUE` | allow Kitty protocol |
| `use_sixel` | `TRUE` | accepted for API compatibility; a no-op unless the Rust crate is built with its `sixel` feature (the default build is not) |

## Terminal support in one paragraph

Protocol precedence: Sixel (build-dependent) → iTerm (`TERM_PROGRAM` contains iTerm, WezTerm, mintty, rio or WarpTerminal, and `LC_TERMINAL` the same except WarpTerminal) → Kitty (`TERM` contains kitty or ghostty) → coloured half-blocks in ANSI. In RStudio, Positron, IDE consoles, `Rscript` with redirected output and CI logs there is no graphics terminal, so the half-block fallback writes raw escape sequences into the log stream. Bytes are written straight to stdout from Rust, so `sink()` and `capture.output()` do not capture a rendered image. Verify the environment before promising a rendered image; `scripts/check_terminal.R` prints the detection result, terminal size and an optional test render. Details and the sizing arithmetic: `references/terminal-support.md`.

## Full API and recipes

- `references/api.md` — signatures, argument meanings, return values, internal diagnostics helpers, error messages.
- `references/recipes.md` — copy-paste patterns: fit-to-terminal, transparent logos, animations, capture without rendering, custom pixel fonts, non-TTY handling.
- `scripts/check_terminal.R` — run `Rscript scripts/check_terminal.R` (add `--render` for a test image) to explain a misbehaving setup.

## Pitfalls and error messages

| Message | Cause | Fix |
| --- | --- | --- |
| `Class <ggplot2::ggplot/...> is not supported` | a plot object passed straight to `render_plot()` | wrap it: `capture_plot(p) |> render_plot()` |
| `'x.png' not exist` | path typo or relative path resolved elsewhere | use `normalizePath()` / absolute path |
| `raw should not be provided when rendering plot from file` | both `render_plot.character` and `raw =` | pass one source only |
| `file_path should not be provided when rendering plot from R` | both `render_plot.raw` and `file_path =` | pass one source only |
| `Image decoding failed: ...` | `raw` is not PNG bytes (JPEG, SVG, screenshot) | write it to a file and pass the path, or convert with `png::writePNG()` |
| `Nothing was drawn by expr` | `expr` drew nothing (e.g. `capture_plot(1 + 1)`, which only prints `2`) | put actual drawing code in `expr` |
| `No glyph defined for "#"` | character outside the 3x5 font (`A-Z`, `0-9`, space, `.`, `,`, `-`, `:`, `!`, `?`) | add it with `pixel_font_add()` |
| `A glyph must be a character vector of 5 strings ...` | malformed glyph rows | rows must be 5 strings of three `0`/`1` characters |
| `must be a single string` / `single character` | vectorised input to `text_to_matrix()`, `get_glyph()` | loop or `paste0()` first |
| `The package "ggplot2" is required` | `draw_pixels()`/`draw_matrix()` without ggplot2 | `install.packages("ggplot2")` (it is only in Suggests) |

In package code, keep rendering calls inside `\donttest{}` or interactive branches: the output depends on the device and the terminal.
