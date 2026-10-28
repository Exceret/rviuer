# rviuer (development version)

* Images are drawn on R's message stream (stderr) instead of stdout, the
  convention the cli package follows: `sink()` and `capture.output()` no longer
  swallow a rendered image, while `sink(type = "message")` and
  `capture.output(type = "message")` capture or silence it. Use
  `get_viuer_config(output = "stdout")` to keep drawing on the ordinary output
  stream.
* The `viuer` crate is now vendored under `src/rust/src/viuer/` (MIT, see
  `LICENSE.note`), so the drawing writes to the writer the R side hands it
  instead of the process stdout. The upstream `print()` and `print_from_file()`
  entry points are kept for reference.
* The minimum supported Rust version is now 1.80, which the vendored code needs.

# rviuer 0.1.0

* Initial submission.
