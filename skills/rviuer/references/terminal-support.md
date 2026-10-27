# Terminal support and sizing

How rviuer decides what to print, and why the size comes out as it does. Behaviour below is taken from `src/rust/src/receiver/receiver.rs`, the R wrappers in `R/`, and the vendored `viuer` 0.9.2 crate.

## Protocol selection

`viuer` picks a printer on every print call, in this order:

1. **Sixel** — only when the Rust crate is built with the `sixel` feature. rviuer's `Cargo.toml` has `default = []`, so a normal install never reaches this branch and `use_sixel` is ignored.
2. **iTerm** — `TERM_PROGRAM` contains `iTerm`, `WezTerm`, `mintty`, `rio` or `WarpTerminal`, or `LC_TERMINAL` contains `iTerm`, `WezTerm`, `mintty` or `rio`.
3. **Kitty** — `TERM` contains `kitty` or `ghostty`.
4. **Half-blocks** — ANSI coloured upper/lower block characters, always available.

Sixel detection (only relevant when built with the feature), for reference: `TERM` in `mlterm`, `yaft-256color`, `foot`, `foot-extra`, `eat-truecolor`, `rio`; `TERM` in `st-256color`, `xterm`, `xterm-256color` triggers a device-attributes query; otherwise `TERM_PROGRAM == "MacTerm"`.

The detection results are cached in a lazy static, so changing environment variables inside a running R session does not re-probe the terminal: set them before starting R (or restart the session).

Consequences:

- RStudio, Positron, VS Code terminals, Emacs/ESS, a plain `Rscript` piped to a file and CI logs are not iTerm/Kitty terminals → half-block fallback. Escape sequences will end up in the log; use `isatty(stdout())` / `interactive()` to guard.
- Output is written straight to the process's stdout file descriptor from Rust. R's `sink()` and `capture.output()` do **not** capture a rendered image — verified: the escape bytes still reach the console while `capture.output()` returns zero lines.

## Colour depth

- Truecolor (24-bit) is used when `config.truecolor = TRUE` **and** `COLORTERM` contains `truecolor` or `24bit`; otherwise colours are quantised to 256 ANSI colours.
- Alpha handling in the half-block printer:
  - `transparent = FALSE` (default): fully and partially transparent pixels are composited onto a checkerboard pattern, imitating transparency.
  - `transparent = TRUE`: fully transparent pixels are skipped (the terminal background shows through); partially transparent pixels keep their raw RGB because an ANSI cell has no alpha.
  - `premultiplied_alpha` chooses Porter-Duff premultiplied compositing instead of straight-alpha blending when compositing happens.

## Terminal size

`viuer::terminal_size()` asks the terminal (`TIOCGWINSZ` on the output descriptor) and falls back to **80 x 24** when there is no terminal. The same value is exposed for debugging as `rviuer:::terminal_size()`, so an unexpected 80x24 is usually a sign that stdout is not a TTY.

## Fitting an image to the terminal

When the config has neither `width` nor `height`, rviuer computes the cell size itself (`fit_cells` in `receiver.rs`):

- Usable area is `(term_width - 1) x (term_height - 1)`: one column and one row are kept free so a cell in the last column cannot trigger the terminal's automatic line wrap.
- An image that already fits (`img_width <= max_width` and `img_height <= 2 * max_height`) is printed unchanged — small images are never scaled up. Its cell height is `ceil(img_height / 2)`.
- Otherwise the width is set to `max_width` and the height follows from the aspect ratio, rounded to the nearest cell: `round(img_height * width / img_width / 2)`.
- If that height still exceeds `max_height`, the image is fitted to `max_height` instead, the width is recomputed, and a warning `Plot height is reset to max height` is emitted.

```r
rviuer:::fit_terminal_cells(1600, 900, 80, 24)   # c(79, 22)
rviuer:::fit_terminal_cells(60, 40, 80, 24)      # c(60, 20) — already fits, unchanged
```

If exactly one of `width`/`height` is set, rviuer passes it through untouched and `viuer` derives the other from the aspect ratio. If both are set, they are used verbatim (may overflow).

## Offsets and cursor

- `x` moves right by that many cells, `y` moves down (negative = up).
- `absolute_offset = FALSE`: `y` is relative to the current cursor row; `absolute_offset = TRUE`: `x`/`y` are relative to the terminal's top-left corner.
- `restore_cursor = TRUE`: the cursor position is saved before printing and restored afterwards, which is what makes in-place redraws and animations work.

## Practical checks before promising an image

```r
rviuer::render_plot("logo.png")   # works, writes to the console
isatty(stdout())                  # FALSE -> output is going to a pipe/log
Sys.getenv(c("TERM", "TERM_PROGRAM", "LC_TERMINAL", "COLORTERM"))
```

`scripts/check_terminal.R` bundles these checks plus an optional test render.
