# rviuer API reference

Everything here comes from the package sources (`R/`, `src/rust/`) at version 0.1.0. Functions marked **internal** are called with `rviuer:::` and exist for diagnostics only.

## Rendering

### `render_plot(x, config = get_viuer_config(), ...)`

S3 generic that draws an image in the terminal.

| Method | `x` | Behaviour |
| --- | --- | --- |
| `render_plot.character` | path to a file | aborts if `!file.exists(x)`; forwards `file_path = x` to `print_image()`; rejects a `raw` argument |
| `render_plot.raw` | PNG bytes | forwards `raw = x`; rejects a `file_path` argument |
| `render_plot.default` | anything else | aborts listing the available classes |

- Returns `TRUE`, invisibly.
- Images go to R's **message stream (stderr)** by default, the way `cli` writes its messages: `sink()` and `capture.output()` leave them alone, `sink(type = "message")` / `capture.output(type = "message")` capture them. `get_viuer_config(output = "stdout")` draws on the ordinary output stream instead.
- `...` is forwarded to the Rust entry point (`print_image()`), not to `viuer` directly; the package validates the two source arguments, so besides `config` only `output` is useful there.
- File paths are decoded with `image`'s guessed format; `raw` bytes are always decoded as PNG.

```r
render_plot("plot.png")
render_plot("plot.png", config = get_viuer_config(width = 60))
capture_plot(plot(1:10)) |> render_plot(get_viuer_config(width = 40))
```

### `capture_plot(expr, width = 7L, height = 7L, units = c("in", "cm", "mm", "px"), res = 96L, bg = "white", ...)`

Runs `expr` on an in-memory `ragg::agg_capture()` device and returns the last page as PNG-encoded `raw` bytes. No temporary file is created.

- `expr`: a single expression or braced block; evaluated after the device opens, so the device is active.
- `width`, `height`: physical size of the PNG; fractional values allowed (`rlang::check_number_decimal`).
- `units`: one of `"in"`, `"cm"`, `"mm"`, `"px"`.
- `res`: pixels per inch, whole number.
- `bg`: background colour.
- `...`: forwarded to `ragg::agg_capture()` (`pointsize`, `scaling`, ...).
- A visible result is `print()`ed, so `capture_plot(ggplot_obj)` works; base graphics draw directly.
- Aborts with `Nothing was drawn by expr` when every captured pixel has the same value.
- The previous device is restored afterwards.
- Multiple pages: only the last one is returned.

```r
r <- capture_plot(plot(1:10), width = 4, height = 3, units = "in", res = 150)
r <- capture_plot({
  par(mfrow = c(1, 2))
  hist(rnorm(100))
  boxplot(mpg ~ cyl, data = mtcars)
}, width = 8, height = 3)
```

### **internal** `print_image(config, file_path = NULL, raw = NULL, output = NULL)`

Rust entry point (`.Call`). Exactly one of `file_path` / `raw` must be supplied, otherwise `supply either file_path or raw` / `supply only one of file_path and raw`. When the config has no `width`/`height`, it reads the image dimensions (`image::ImageReader`, header only for files), queries the terminal size and fills in the fitted cell size, warning when the height had to be capped. Prefer `render_plot()`.

`output` is the R console channel: `"stderr"` (R's message stream) or `"stdout"` (R's output stream). `NULL` falls back to the `output` element of `config`, and to `"stderr"` when that is absent too, so a configuration list built by `get_viuer_config()` is enough. Any other value aborts with `` `output` must be "stderr" or "stdout" ``.

## Configuration

### `get_viuer_config(transparent = FALSE, premultiplied_alpha = FALSE, absolute_offset = FALSE, x = 0L, y = 0L, restore_cursor = FALSE, width = NULL, height = NULL, truecolor = TRUE, use_kitty = TRUE, use_iterm = TRUE, use_sixel = TRUE, output = c("stderr", "stdout"))`

Returns a named list (also the default of `render_plot(config = ...)`) with those thirteen elements. All logicals go through `rlang::check_bool()`; `x`, `y`, `width`, `height` go through `rlang::check_number_whole()`; `output` goes through `rlang::arg_match0()`.

- `x` range checked again in Rust: `[0, 65535]`.
- `y` range checked again in Rust: `[-32768, 32767]`.
- `width`/`height` are terminal **cells**, `NULL` means "fit the terminal".
- Missing or `NULL` fields fall back to the vendored `viuer::Config::default()` on the Rust side, so a partial list is valid (but build it with this function).
- `output = "stderr"` (the default) draws on R's message stream, `output = "stdout"` on R's output stream.
- `use_sixel` is only forwarded when the crate is compiled with the `sixel` feature; the default build is not, so it is silently ignored.

```r
str(get_viuer_config(), max.level = 1)
```

## Pixel art

### `draw_pixels(text, font = pixel_font_3x5, spacing = 1L, line_spacing = 1L, fill = "steelblue", background = "white", border = "grey85", border_width = 0.4, color_by = c("none", "letter"), palette = NULL)`

High-level entry point: `text_to_matrix()` then `draw_matrix()`. Returns a `ggplot` object (extendable, `ggsave()`-able). Requires ggplot2.

- `text`: single string; `"\n"` starts a new line. Unknown characters abort.
- `color_by = "letter"`: each character gets its own colour from `palette` (recycled; default `grDevices::hcl.colors(n, "Dark 3")`).
- `background = NA` / `border = NA` removes the empty-pixel fill / grid lines.

```r
draw_pixels("rviuer")
draw_pixels("rviuer", color_by = "letter")
draw_pixels("hello\nworld", fill = "tomato", border = NA)
```

### `draw_matrix(m, fill = "steelblue", background = "white", border = "grey85", border_width = 0.4, color_by = c("none", "letter"), palette = NULL)`

Renders an integer pixel matrix as `geom_tile()` with `coord_fixed()` and `scale_y_reverse()` (row 1 at the top). `0` is empty; positive values are filled. With `color_by = "letter"`, distinct positive values get distinct colours. Returns a `ggplot`.

### `text_to_matrix(text, font = pixel_font_3x5, spacing = 1L, line_spacing = 1L, index = FALSE)`

Builds an integer matrix, 5 rows per text line, `3 * nchar + spacing * (nchar - 1)` columns per line (lines padded to equal width). `index = TRUE` multiplies the n-th character's pixels by `n` so each letter can be coloured separately. `spacing`/`line_spacing` must be `>= 0`.

```r
dim(text_to_matrix("AB"))                 # 5 7
dim(text_to_matrix("AB\nC", line_spacing = 2))  # 12 7
```

### `matrix_to_pixels(m)`

Long data frame with `row`, `col` (1-based, `row` from the top) and `value`. Errors if `m` is not a matrix.

### `pixel_font_3x5`

Named list of glyphs: `A`-`Z`, `0`-`9`, space, `.`, `,`, `-`, `:`, `!`, `?`. Each element is 5 strings of 3 characters from `"0"`/`"1"`, top row first. Letters are stored upper case.

### `get_glyph(char, font = pixel_font_3x5)`

Returns a 5x3 integer matrix of `0`/`1`. Case-insensitive. Aborts on multi-character input or an undefined character (`No glyph defined for ...`).

### `pixel_font_add(font = pixel_font_3x5, char, rows)`

Returns a modified copy of `font` (the original list is not touched), adding or replacing `char` (stored upper case). `rows` must pass `check_glyph()`.

```r
font <- pixel_font_add(pixel_font_3x5, "#", c("101", "111", "101", "111", "101"))
get_glyph("#", font)
draw_pixels("C#", font = font)
```

### `check_glyph(rows)`

Validates five strings matching `^[01]{3}$`; returns `TRUE` invisibly, otherwise aborts.

## Diagnostic helpers (internal)

| Function | Returns |
| --- | --- |
| `rviuer:::terminal_size()` | list `width`, `height` in cells as reported by the terminal (`TIOCGWINSZ`); falls back to `80 x 24` when there is no terminal |
| `rviuer:::fit_terminal_cells(img_width, img_height, term_width, term_height)` | integer vector `c(columns, rows)` the image would occupy; warns when the height is capped |
| `rviuer:::print_image(config, file_path, raw, output)` | the low-level Rust call behind `render_plot()` |

```r
rviuer:::terminal_size()
rviuer:::fit_terminal_cells(1600, 900, 80, 24)  # c(79, 22) for a 16:9 image in 80x24
```

## Version caveat

`text_to_matrix()`, `matrix_to_pixels()`, `draw_matrix()` and `check_glyph()` are exported by the development version on GitHub. Older installed builds export only `capture_plot()`, `render_plot()`, `get_viuer_config()`, `draw_pixels()`, `pixel_font_3x5`, `get_glyph()` and `pixel_font_add()`. Check with `getNamespaceExports("rviuer")` before using the pixel-matrix helpers.
