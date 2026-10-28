// Vendored source: `viuer` 0.11.0 (MIT), <https://github.com/atanunq/viuer>.
// See `LICENSE.note` at the package root for the full attribution.
//
// This is a module of the `rviuer` crate, not a crate of its own, so it is kept
// as close to upstream as possible: a new upstream release can then be diffed
// in. Everything that was changed on purpose is listed here.
//
// Changes against upstream 0.11.0
// -------------------------------
// 1. Crate-level attributes (`#![deny(missing_docs)]` and
//    `#![allow(clippy::uninlined_format_args)]`) were dropped, and `crate::`
//    paths became `crate::viuer::`, because a module cannot carry the attributes
//    of a crate root.
// 2. `print_to()` and `print_from_file_to()` were added. They take the writer
//    the image is emitted to, so the R side can route the output to R's stderr
//    instead of the process stdout. `print()` and `print_from_file()` keep the
//    upstream behaviour (stdout) and now delegate to them.
// 3. `BlockPrinter` renders into a `termcolor::Ansi` buffer and hands the bytes
//    to the caller's writer, instead of opening a
//    `BufferedStandardStream::stdout` of its own. Consequence: colours are now
//    always emitted as ANSI escape sequences, including on Windows, where the
//    previous code used the console API when one was attached.
// 4. `check_kitty_support()` and `check_sixel_support()` send their queries to
//    stderr: they must reach the terminal the image is drawn on, and that is no
//    longer stdout.
//
// Known limitation: the sixel printers hand the frame to `sixel_rs` /
// `icy_sixel`, which keep their own output handling, so `print_to`'s writer is
// only honoured by the `icy_sixel` printer. Sixel support is optional, needs
// extra crates and is not exercised by this package's tests.

#![allow(dead_code)]

//! Library to display images in the terminal.
//!
//! This library contains functionality extracted from the [`viu`](https://github.com/atanunq/viu) crate.
//! It aims to provide an easy to use interface to print images in the terminal. Uses some abstractions
//! provided by the [`image`] crate. [Kitty](https://sw.kovidgoyal.net/kitty/graphics-protocol.html)
//! and [iTerm](https://iterm2.com/documentation-images.html) graphic protocols are supported and used by default,
//! if detected. If not, `viuer` will fallback to using regular half blocks instead (▄ and ▀).
//!
//! ## Basic Usage
//! The default features of this crate can only work with [image::DynamicImage]. The below example
//! creates a 60x60 gradient and prints it. More options are available through the [Config] struct.
//! ```ignore
//! use image::{DynamicImage, Pixel, Rgba, RgbaImage};
//!
//! let conf = viuer::Config {
//!     absolute_offset: false,
//!     ..Default::default()
//! };
//!
//! let mut img = DynamicImage::ImageRgba8(RgbaImage::new(60, 60));
//! let start = Rgba::from_slice(&[0, 196, 0, 255]);
//! let end = Rgba::from_slice(&[255, 255, 255, 255]);
//! image::imageops::horizontal_gradient(&mut img, start, end);
//!
//! viuer::print(&img, &conf).unwrap();
//! ```
//!
//! ## Decoding files
//! To work directly with files, the non-default `print-file` feature must be enabled.
//!
//! The example below shows how to print the image `img.jpg` in 40x30 terminal cells, with vertical
//! offset of 4 and horizontal of 10, starting from the top left corner.
//! ```ignore
//! let conf = viuer::Config {
//!     width: Some(40),
//!     height: Some(30),
//!     x: 10,
//!     y: 4,
//!     ..Default::default()
//! };
//!
//! #[cfg(feature="print-file")]
//! viuer::print_from_file("img.jpg", &conf).expect("Image printing failed.");
//! ```

#[cfg(feature = "print-file")]
use std::path::Path;

use console::Term;
use crossterm::{
    cursor::{RestorePosition, SavePosition},
    execute,
};
use image::DynamicImage;
use printer::{Printer, PrinterType};
use std::io::Write;

mod config;
mod error;
mod printer;
mod utils;

pub use config::Config;
// The rest of the upstream public surface is re-exported even where this
// package does not use it: it keeps the vendored copy diffable against
// upstream 0.11.0, and some of it is only reachable through the optional
// sixel printers.
#[allow(unused_imports)]
pub use error::{ViuError, ViuResult};
#[allow(unused_imports)]
pub use printer::{get_kitty_support, is_iterm_supported, resize, KittySupport};
pub use utils::terminal_size;

#[cfg(any(feature = "sixel", feature = "icy_sixel"))]
pub use printer::is_sixel_supported;

/// Default printing method. Uses either iTerm or Kitty graphics protocol, if supported,
/// and half blocks otherwise.
///
/// Prints to stdout; use [`print_to`] to choose the writer.
///
/// Check the [Config] struct for all customization options.
/// ## Example
/// The snippet below reads all of stdin, decodes it with the [`image`] crate
/// and prints it to the terminal. The image will also be resized to fit in the terminal.
///
/// ```ignore
/// use std::io::{stdin, Read};
/// use viuer::{Config, print};
///
/// let stdin = stdin();
/// let mut handle = stdin.lock();
///
/// let mut buf: Vec<u8> = Vec::new();
/// let _ = handle
///     .read_to_end(&mut buf)
///     .expect("Could not read until EOF.");
///
/// let img = image::load_from_memory(&buf).expect("Data from stdin could not be decoded.");
/// print(&img, &Config::default()).expect("Image printing failed.");
/// ```
pub fn print(img: &DynamicImage, config: &Config) -> ViuResult<(u32, u32)> {
    let mut stdout = std::io::stdout();
    print_to(img, config, &mut stdout)
}

/// Print `img` to `out`, using the same protocol selection as [`print`].
///
/// `out` receives every byte of the drawing, escape sequences included, so the
/// caller decides where the image ends up: the process stdout, stderr, a buffer
/// for testing, or a host language's own console channel.
///
/// Returns the size of the printed image, in terminal cells.
pub fn print_to(
    img: &DynamicImage,
    config: &Config,
    out: &mut impl Write,
) -> ViuResult<(u32, u32)> {
    if config.restore_cursor {
        execute!(out, SavePosition)?;
    }

    // This is required to get a "Term" instance for "::read_key"
    let term = Term::stderr();

    let (w, h) = choose_printer(config).print(&term, out, img, config)?;

    if config.restore_cursor {
        execute!(out, RestorePosition)?;
    };

    Ok((w, h))
}

/// Helper method that reads a file, tries to decode and print it. The feature is available only
/// with the `print-file` feature.
///
/// ## Example
/// ```ignore
/// use viuer::{Config, print_from_file};
/// let conf = Config {
///     width: Some(30),
///     transparent: true,
///     ..Default::default()
/// };
/// // Image will be scaled down to width 30. Aspect ratio will be preserved.
/// // Also, the terminal's background color will be used instead of checkerboard pattern.
/// print_from_file("img.jpg", &conf).expect("Image printing failed.");
/// ```
#[cfg(feature = "print-file")]
pub fn print_from_file<P: AsRef<Path>>(filename: P, config: &Config) -> ViuResult<(u32, u32)> {
    let mut stdout = std::io::stdout();
    print_from_file_to(filename, config, &mut stdout)
}

/// Read the image stored at `filename` and print it to `out`.
///
/// Same as [`print_from_file`], with the writer chosen by the caller. Only
/// available with the `print-file` feature.
#[cfg(feature = "print-file")]
pub fn print_from_file_to<P: AsRef<Path>>(
    filename: P,
    config: &Config,
    out: &mut impl Write,
) -> ViuResult<(u32, u32)> {
    if config.restore_cursor {
        execute!(out, SavePosition)?;
    }

    // This is required to get a "Term" instance for "::read_key"
    let term = Term::stderr();

    let (w, h) = choose_printer(config).print_from_file(&term, out, filename, config)?;

    if config.restore_cursor {
        execute!(out, RestorePosition)?;
    };

    Ok((w, h))
}

// Choose the appropriate printer to use based on user config and availability
fn choose_printer(config: &Config) -> PrinterType {
    #[cfg(any(feature = "icy_sixel", all(feature = "sixel", windows)))]
    if config.use_sixel && is_sixel_supported() {
        return PrinterType::IcySixel;
    }

    #[cfg(all(feature = "sixel", not(windows)))]
    if config.use_sixel && is_sixel_supported() {
        return PrinterType::Sixel;
    }

    if config.use_iterm && is_iterm_supported() {
        PrinterType::iTerm
    } else if config.use_kitty && get_kitty_support() != KittySupport::None {
        PrinterType::Kitty
    } else {
        PrinterType::Block
    }
}
