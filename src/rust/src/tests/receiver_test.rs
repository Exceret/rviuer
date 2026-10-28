//! Tests for the printing logic in `src/receiver/receiver.rs`.
//!
//! The R-facing entry points need an R runtime, which `cargo test` does not
//! start, so these tests only cover the part of the module that works on plain
//! Rust values: the size arithmetic, the image header reading and the error
//! reporting. Everything that goes through `List`, `Rstr` or `Raw` is covered by
//! the testthat suite instead.

use super::*;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU32, Ordering};

#[test]
fn fit_cells_fits_a_wide_image_to_the_width() {
    // the 10 x 3 in capture at 96 dpi, printed in an 80 x 24 terminal
    assert_eq!(
        fit_cells(960, 288, 80, 24),
        Cells {
            width: 79,
            height: 12,
            height_capped: false,
        }
    );
}

#[test]
fn fit_cells_fits_a_tall_image_to_the_height() {
    // 3 x 10 in capture, same terminal: the width fit overflows
    assert_eq!(
        fit_cells(288, 960, 80, 24),
        Cells {
            width: 14,
            height: 23,
            height_capped: true,
        }
    );
}

#[test]
fn fit_cells_fits_a_square_image_to_the_height() {
    // the 7 x 7 in capture (672 x 672 px): height bound, width follows
    assert_eq!(
        fit_cells(672, 672, 80, 24),
        Cells {
            width: 46,
            height: 23,
            height_capped: true,
        }
    );
}

#[test]
fn fit_cells_keeps_images_that_already_fit() {
    assert_eq!(
        fit_cells(4, 3, 80, 24),
        Cells {
            width: 4,
            height: 2,
            height_capped: false,
        }
    );
    assert_eq!(
        fit_cells(79, 46, 80, 24),
        Cells {
            width: 79,
            height: 23,
            height_capped: false,
        }
    );
}

#[test]
fn fit_cells_keeps_degenerate_sizes_usable() {
    assert_eq!(
        fit_cells(0, 0, 80, 24),
        Cells {
            width: 1,
            height: 1,
            height_capped: false,
        }
    );
    assert_eq!(
        fit_cells(960, 288, 1, 1),
        Cells {
            width: 1,
            height: 1,
            height_capped: false,
        }
    );
}

#[test]
fn fit_cells_keeps_the_last_row_and_column_free() {
    let terminals = [(80, 24), (1, 1), (120, 30), (999, 2)];
    let images = [(960, 288), (672, 672), (288, 960), (1, 1)];

    for (term_width, term_height) in terminals {
        for (img_width, img_height) in images {
            let cells = fit_cells(img_width, img_height, term_width, term_height);

            assert!(cells.width <= term_width.saturating_sub(1).max(1));
            assert!(cells.height <= term_height.saturating_sub(1).max(1));
            assert!(cells.width >= 1 && cells.height >= 1);
        }
    }
}

#[test]
fn fit_cells_keeps_the_aspect_ratio() {
    let terminals = [(80, 24), (100, 30), (200, 50), (60, 20)];
    let images = [(960, 288), (672, 672), (288, 960), (1600, 900)];

    for (term_width, term_height) in terminals {
        for (img_width, img_height) in images {
            let cells = fit_cells(img_width, img_height, term_width, term_height);
            // a cell holds two image rows, so the printed aspect is 2 * h / w
            let printed = f64::from(2 * cells.height) / f64::from(cells.width);
            let source = f64::from(img_height) / f64::from(img_width);

            assert!(
                (printed - source).abs() / source < 0.05,
                "{img_width}x{img_height} in {term_width}x{term_height}: \
                 printed {printed}, source {source}"
            );
        }
    }
}

#[test]
fn cells_for_width_rounds_to_the_nearest_cell() {
    assert_eq!(cells_for_width(288, 960, 10), 2); // 1.5 cells
    assert_eq!(cells_for_width(960, 960, 10), 5);
    assert_eq!(cells_for_width(100, 1000, 10), 1); // 0.5 cells, not 0
}

#[test]
fn cells_for_height_inverts_cells_for_width() {
    let images = [(960, 288), (672, 672), (288, 960), (1600, 900)];

    for (img_width, img_height) in images {
        for width in [40, 79, 199] {
            let height = cells_for_width(img_height, img_width, width);
            let round_trip = cells_for_height(img_height, img_width, height);

            assert!(
                round_trip.abs_diff(width) <= 1,
                "{img_width}x{img_height} at {width} cells: back to {round_trip}"
            );
        }
    }
}

#[test]
fn image_dimensions_reads_the_png_header() {
    let image = TempFile::png(7, 3);

    assert_eq!(image_dimensions(image.path()), Some((7, 3)));
}

#[test]
fn image_dimensions_ignores_files_it_cannot_read() {
    let text = TempFile::text("not an image");

    assert_eq!(image_dimensions(text.path()), None);
    assert_eq!(image_dimensions(&missing_path()), None);
}

#[test]
fn fit_config_to_terminal_keeps_explicit_sizes() {
    let mut width_only = Config {
        width: Some(10),
        ..Config::default()
    };
    fit_config_to_terminal(&mut width_only, 960, 288);
    assert_eq!(width_only.width, Some(10));
    assert_eq!(width_only.height, None);

    let mut height_only = Config {
        height: Some(5),
        ..Config::default()
    };
    fit_config_to_terminal(&mut height_only, 960, 288);
    assert_eq!(height_only.width, None);
    assert_eq!(height_only.height, Some(5));
}

#[test]
fn fit_config_to_terminal_fills_in_both_dimensions() {
    // a small image is printed at its own size, whatever the terminal is
    let mut config = Config::default();
    fit_config_to_terminal(&mut config, 4, 3);

    assert_eq!(config.width, Some(4));
    assert_eq!(config.height, Some(2));
}

#[test]
fn print_from_raw_rejects_bytes_that_are_not_png() {
    let mut config = Config::default();

    let err = Receiver::print_from_raw(
        &mut config,
        b"not a png",
        &mut RConsoleWriter::new(Output::Stderr),
    )
    .expect_err("bytes that are not a PNG cannot be decoded");

    assert!(
        err.to_string().contains("Image decoding failed"),
        "unexpected error: {err}"
    );
}

#[test]
fn print_reports_printing_failures() {
    let receiver = Receiver {
        config: Config {
            width: Some(1),
            height: Some(1),
            ..Config::default()
        },
        receiver_type: ReceiverType::FromFilePath(missing_path()),
        output: Output::Stderr,
    };

    let err = receiver
        .print()
        .expect_err("a file that does not exist cannot be printed");

    assert!(
        err.to_string().contains("Image printing failed"),
        "unexpected error: {err}"
    );
}

/// Name of a file that is never created, for the error paths.
fn missing_path() -> String {
    std::env::temp_dir()
        .join(format!("rviuer-missing-{}.png", next_file_id()))
        .to_str()
        .expect("the temp path is not valid UTF-8")
        .to_string()
}

/// Counter behind [`next_file_id`], so a test never reuses a file name.
static NEXT_FILE_ID: AtomicU32 = AtomicU32::new(0);

fn next_file_id() -> u32 {
    NEXT_FILE_ID.fetch_add(1, Ordering::Relaxed)
}

/// A file in the temp directory, removed when the test ends.
struct TempFile {
    path: PathBuf,
}

impl TempFile {
    fn png(width: u32, height: u32) -> Self {
        let file = Self::new("png");
        let image = image::RgbaImage::from_pixel(width, height, image::Rgba([255, 0, 0, 255]));
        image
            .save(&file.path)
            .expect("the test image could not be written");

        file
    }

    fn text(contents: &str) -> Self {
        let file = Self::new("txt");
        std::fs::write(&file.path, contents).expect("the test file could not be written");

        file
    }

    fn new(extension: &str) -> Self {
        Self {
            path: std::env::temp_dir().join(format!(
                "rviuer-{}-{}.{extension}",
                std::process::id(),
                next_file_id()
            )),
        }
    }

    fn path(&self) -> &str {
        self.path
            .to_str()
            .expect("the temp path is not valid UTF-8")
    }
}

impl Drop for TempFile {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.path);
    }
}
