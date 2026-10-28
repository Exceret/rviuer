//
use crate::msg::alert_warning;
use crate::output::{Output, RConsoleWriter};
use crate::viuer::Config;
use extendr_api::{
    extendr, extendr_module, Error, Integers, List, Nullable, Raw, Result, Robj, Rstr, Rtype, Types,
};

enum ReceiverType {
    /// Path of the image file to print.
    FromFilePath(String),
    /// PNG-encoded bytes, as returned by the R side (e.g. `capture_plot()`).
    ///
    /// The [`Raw`] handle is held instead of a `&[u8]`: `Raw::as_slice` borrows
    /// from the handle, so a slice could not outlive the conversion function.
    /// Holding the handle keeps the R vector alive and the slice is taken at the
    /// point of use, with no copy.
    FromRaw(Raw),
}

struct Receiver {
    config: Config,
    receiver_type: ReceiverType,
    output: Output,
}

/// Print an image to the console.
///
/// This is the R-facing entry point: `file_path` arrives as an `Rstr` and `raw`
/// as an R raw vector, and both are converted here, so that `Receiver` only
/// ever deals with Rust types.
///
/// Exactly one of `file_path` and `raw` must be supplied. `raw` is expected to
/// hold a PNG-encoded image (e.g. the output of `capture_plot()`); the format is
/// not sniffed, so the bytes are always decoded as PNG.
///
/// The image-source arguments are nullable: the generated R wrapper declares
/// them with `= NULL`, so callers can omit the one they do not use instead of
/// passing `NULL` explicitly.
///
/// @param config The printing options, as a named list. The `output` element
///   set by [get_viuer_config()] is honoured when `output` is `NULL`.
/// @param file_path,raw The image source; exactly one of them.
/// @param output The R console channel to write to: `"stderr"` (R's message
///   stream, the default when neither this argument nor the `output` element of
///   `config` is given) or `"stdout"` (R's output stream). Writing to stderr
///   keeps R's ordinary output clean, the way the cli package does.
///
/// @keywords internal
#[extendr]
fn print_image(
    config: List,
    #[extendr(default = "NULL")] file_path: Nullable<Rstr>,
    #[extendr(default = "NULL")] raw: Nullable<Raw>,
    #[extendr(default = "NULL")] output: Nullable<Rstr>,
) -> Result<()> {
    // Resolve the channel first: `config` is moved into the receiver.
    let output = output_from_r(&config, output)?;

    Receiver::new(config, receiver_type_from_r(file_path, raw)?, output)?.print()
}

/// Size of the terminal, in cells.
///
/// Returns `width` (columns) and `height` (rows) as reported by the terminal
/// itself, i.e. through `TIOCGWINSZ` on the controlling terminal, which is also
/// where the image is written to (R's stderr). When there is no terminal (a
/// pipe, `Rscript` with redirected output, ...) the size cannot be queried and
/// the fallback of 80 x 24 is returned.
///
/// This is the same value [`fit_terminal_cells`] uses internally, so it is
/// useful to check why an image came out at a given size.
///
/// @return A list with the integer elements `width` and `height`.
///
/// @keywords internal
#[extendr]
fn terminal_size() -> Result<List> {
    let (width, height) = crate::viuer::terminal_size();

    List::from_names_and_values(
        vec!["width", "height"],
        vec![i32::from(width), i32::from(height)],
    )
}

/// Size, in terminal cells, that an image is printed at.
///
/// @param img_width,img_height Size of the image, in pixels.
/// @param term_width,term_height Size of the terminal, in cells.
///
/// @return An integer vector of length two: the number of columns and the
///   number of rows (cells) the image occupies.
///
/// @keywords internal
#[extendr]
fn fit_terminal_cells(
    img_width: u32,
    img_height: u32,
    term_width: u32,
    term_height: u32,
) -> Integers {
    let cells = fit_cells(img_width, img_height, term_width, term_height);
    warn_if_height_capped(&cells);

    Integers::from_values(vec![cells.width as i32, cells.height as i32])
}

/// Convert the R-side image source into a [`ReceiverType`].
///
/// The `Raw` handle is moved into [`ReceiverType::FromRaw`] rather than being
/// borrowed: `Raw::as_slice` ties its `&[u8]` to the handle, so the slice cannot
/// escape this function. The handle is a cheap reference to the R vector, so
/// moving it costs nothing and no bytes are copied.
fn receiver_type_from_r(file_path: Nullable<Rstr>, raw: Nullable<Raw>) -> Result<ReceiverType> {
    match (file_path, raw) {
        (Nullable::NotNull(file_path), Nullable::Null) => {
            let file_path: &str = file_path.as_ref();
            Ok(ReceiverType::FromFilePath(file_path.to_string()))
        }
        (Nullable::Null, Nullable::NotNull(raw)) => Ok(ReceiverType::FromRaw(raw)),
        (Nullable::Null, Nullable::Null) => Err(Error::Other(
            "supply either `file_path` or `raw`".to_string(),
        )),
        (Nullable::NotNull(_), Nullable::NotNull(_)) => Err(Error::Other(
            "supply only one of `file_path` and `raw`".to_string(),
        )),
    }
}

impl Receiver {
    /// Create a receiver from the options collected on the R side.
    ///
    /// `config` is the named list of printing options (`transparent`, `x`, `y`,
    /// `width`, `truecolor`, ...). An option that is missing or `NULL` keeps the
    /// corresponding [`Config::default`] value.
    fn new(config: List, receiver_type: ReceiverType, output: Output) -> Result<Self> {
        Ok(Self {
            config: config_from_list(&config)?,
            receiver_type,
            output,
        })
    }

    /// Print the image described by `receiver_type`.
    ///
    /// The receiver is consumed so the owned [`Raw`] handle stays alive while
    /// the image is decoded: `raw.as_slice()` borrows from it, so the borrow
    /// lives no longer than this call and no bytes are copied.
    ///
    /// `config` is mutable because the size is filled in here, once the image
    /// dimensions are known (see [`fit_config_to_terminal`]).
    fn print(self) -> Result<()> {
        let Self {
            mut config,
            receiver_type,
            output,
        } = self;

        // Every byte of the drawing goes through this writer, so the image ends
        // up in R's console channel instead of the process stdout.
        let mut writer = RConsoleWriter::new(output);

        match receiver_type {
            ReceiverType::FromRaw(raw) => {
                Self::print_from_raw(&mut config, raw.as_slice(), &mut writer)
            }
            ReceiverType::FromFilePath(file_path) => {
                Self::print_from_str(&mut config, &file_path, &mut writer)
            }
        }
    }

    /// Print a PNG-encoded byte buffer.
    fn print_from_raw(config: &mut Config, raw: &[u8], writer: &mut RConsoleWriter) -> Result<()> {
        let image = image::load_from_memory_with_format(raw, image::ImageFormat::Png)
            .map_err(|err| Error::Other(format!("Image decoding failed: {err}")))?;

        fit_config_to_terminal(config, image.width(), image.height());

        crate::viuer::print_to(&image, config, writer)
            .map_err(|err| Error::Other(format!("Image printing failed: {err}")))?;

        Ok(())
    }

    /// Print the image stored at `file_path`.
    fn print_from_str(
        config: &mut Config,
        file_path: &str,
        writer: &mut RConsoleWriter,
    ) -> Result<()> {
        // Only the header is read here, so the size can be fitted before the
        // image itself is decoded (by `viuer::print_from_file_to`, which keeps
        // its own error messages).
        if let Some((width, height)) = image_dimensions(file_path) {
            fit_config_to_terminal(config, width, height);
        }

        crate::viuer::print_from_file_to(file_path, config, writer)
            .map_err(|err| Error::Other(format!("Image printing failed: {err}")))?;

        Ok(())
    }
}

/// Size, in terminal cells, for an image that has to fit the terminal.
///
/// A cell is about twice as tall as it is wide, so two image rows share one
/// cell: the number of rows an image occupies is half its pixel height once it
/// has been scaled to the width. Two details matter:
///
/// * The width keeps one column free. Printing a cell in the last column puts
///   the terminal in its "wrap pending" state, and an image that is exactly as
///   wide as the terminal is sheared on terminals that wrap immediately.
/// * The height is rounded, not truncated. `viuer` divides the scaled pixel
///   height by two, which squashes a wide image vertically (up to a full cell,
///   i.e. several percent of its height).
///
/// An image that already fits is returned unchanged, so small images are not
/// blown up to the terminal size.
///
/// The computation has no side effects: it only reports through
/// [`Cells::height_capped`] that the image had to be shrunk below the width it
/// was fitted to, so the caller decides whether to tell the user.
fn fit_cells(img_width: u32, img_height: u32, term_width: u32, term_height: u32) -> Cells {
    let img_width = img_width.max(1);
    let img_height = img_height.max(1);
    let max_width = term_width.saturating_sub(1).max(1);
    let max_height = term_height.saturating_sub(1).max(1);

    if img_width <= max_width && img_height <= 2 * max_height {
        return Cells {
            width: img_width,
            // two image rows share one cell, and a trailing odd row still needs
            // a cell of its own
            height: img_height.div_ceil(2),
            height_capped: false,
        };
    }

    // Fit the width first; the height follows from the image aspect ratio.
    let mut width = max_width;
    let mut height = cells_for_width(img_height, img_width, width);
    let mut height_capped = false;

    if height > max_height {
        // The image is too tall for the terminal after scaling: fit it to the
        // height instead and derive the width.
        height_capped = true;
        height = max_height;
        width = cells_for_height(img_height, img_width, height);
    }

    Cells {
        width: width.max(1),
        height: height.max(1),
        height_capped,
    }
}

/// Size, in terminal cells, computed by [`fit_cells`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Cells {
    /// Number of columns the image occupies.
    width: u32,
    /// Number of rows (cells) the image occupies.
    height: u32,
    /// The image was too tall once fitted to the width, so it was shrunk to the
    /// terminal height and the width was derived from it.
    height_capped: bool,
}

/// Tell the user that an image was shrunk to the terminal height.
fn warn_if_height_capped(cells: &Cells) {
    if cells.height_capped {
        alert_warning("Plot height is reset to max height", true);
    }
}

/// Cell rows an image of `img_height` pixels occupies once scaled to `width`.
fn cells_for_width(img_height: u32, img_width: u32, width: u32) -> u32 {
    (f64::from(img_height) * f64::from(width) / f64::from(img_width) / 2.0).round() as u32
}

/// Cell columns an image of `img_width` pixels occupies at `height` cell rows.
fn cells_for_height(img_height: u32, img_width: u32, height: u32) -> u32 {
    (f64::from(img_width) * 2.0 * f64::from(height) / f64::from(img_height)).round() as u32
}

/// Fill in the print size when the caller did not ask for one.
///
/// `width` and `height` are only computed when both are unset: a single
/// explicit dimension is left to `viuer`, which then fits the other one while
/// preserving the aspect ratio.
fn fit_config_to_terminal(config: &mut Config, img_width: u32, img_height: u32) {
    if config.width.is_some() || config.height.is_some() {
        return;
    }

    let (term_width, term_height) = crate::viuer::terminal_size();
    let cells = fit_cells(
        img_width,
        img_height,
        u32::from(term_width),
        u32::from(term_height),
    );
    warn_if_height_capped(&cells);

    config.width = Some(cells.width);
    config.height = Some(cells.height);
}

/// Pixel dimensions of an image file, without decoding its pixels.
///
/// Returns `None` when the file cannot be opened or is not a recognised image;
/// printing then fails with `viuer`'s own error message.
fn image_dimensions(file_path: &str) -> Option<(u32, u32)> {
    image::ImageReader::open(file_path)
        .and_then(|reader| reader.with_guessed_format())
        .ok()?
        .into_dimensions()
        .ok()
}

/// Turn the R-side option list into a [`Config`].
///
/// The list is only read, never modified, and every option is optional: a value
/// that is missing or `NULL` falls back to [`Config::default`], so the caller
/// can send a partial set of options.
fn config_from_list(config: &List) -> Result<Config> {
    let default = Config::default();

    let x = field_integer(config, "x")?.unwrap_or(i64::from(default.x));
    let y = field_integer(config, "y")?.unwrap_or(i64::from(default.y));

    Ok(Config {
        transparent: field_logical(config, "transparent", default.transparent)?,
        premultiplied_alpha: field_logical(
            config,
            "premultiplied_alpha",
            default.premultiplied_alpha,
        )?,
        absolute_offset: field_logical(config, "absolute_offset", default.absolute_offset)?,
        x: u16::try_from(x)
            .map_err(|_| Error::Other("`x` must be a whole number in [0, 65535]".to_string()))?,
        y: i16::try_from(y).map_err(|_| {
            Error::Other("`y` must be a whole number in [-32768, 32767]".to_string())
        })?,
        restore_cursor: field_logical(config, "restore_cursor", default.restore_cursor)?,
        width: field_size(config, "width")?,
        height: field_size(config, "height")?,
        truecolor: field_logical(config, "truecolor", default.truecolor)?,
        use_kitty: field_logical(config, "use_kitty", default.use_kitty)?,
        use_iterm: field_logical(config, "use_iterm", default.use_iterm)?,
        // `Config::use_sixel` only exists when one of the sixel features is
        // enabled, so the option is ignored otherwise and its default (`true`)
        // is spelled out instead of read from `default`.
        #[cfg(any(feature = "sixel", feature = "icy_sixel"))]
        use_sixel: field_logical(config, "use_sixel", true)?,
    })
}

/// Look `name` up in `config`; a missing field or a `NULL` value means unset.
fn list_field(config: &List, name: &str) -> Option<Robj> {
    let value = config.iter().find(|(key, _)| *key == name)?.1;
    if matches!(value.rtype(), Rtype::Null) {
        None
    } else {
        Some(value)
    }
}

/// Read a logical option, falling back to `default` when it is absent.
fn field_logical(config: &List, name: &str, default: bool) -> Result<bool> {
    match list_field(config, name) {
        Some(value) => value
            .as_bool()
            .ok_or_else(|| Error::Other(format!("`{name}` must be TRUE or FALSE"))),
        None => Ok(default),
    }
}

/// Resolve the R console channel the image is written to.
///
/// The `output` argument of [`print_image`] wins; when it is `NULL` the
/// `output` element of the configuration is used, so that a caller who only
/// holds a configuration list still gets the channel it asked for. Without
/// either, the image goes to stderr.
fn output_from_r(config: &List, output: Nullable<Rstr>) -> Result<Output> {
    match output {
        Nullable::NotNull(output) => Output::parse(output.as_ref()),
        Nullable::Null => match field_string(config, "output")? {
            Some(value) => Output::parse(&value),
            None => Ok(Output::Stderr),
        },
    }
}

/// Read a single-string option, falling back to `None` when it is absent.
fn field_string(config: &List, name: &str) -> Result<Option<String>> {
    let value = match list_field(config, name) {
        Some(value) => value,
        None => return Ok(None),
    };

    let value = <&str>::try_from(&value)
        .map_err(|_| Error::Other(format!("`{name}` must be a single string")))?;

    Ok(Some(value.to_string()))
}

/// Read a whole-number option, accepting both integer and double R values.
fn field_integer(config: &List, name: &str) -> Result<Option<i64>> {
    let value = match list_field(config, name) {
        Some(value) => value,
        None => return Ok(None),
    };

    let number = value
        .as_integer()
        .map(i64::from)
        .or_else(|| {
            value
                .as_real()
                .filter(|number| number.fract() == 0.0)
                .map(|number| number as i64)
        })
        .ok_or_else(|| Error::Other(format!("`{name}` must be a single whole number")))?;

    Ok(Some(number))
}

/// Read an optional image dimension; `NULL` and missing both mean `None`.
fn field_size(config: &List, name: &str) -> Result<Option<u32>> {
    match field_integer(config, name)? {
        Some(number) => u32::try_from(number).map(Some).map_err(|_| {
            Error::Other(format!(
                "`{name}` must be a whole number in [0, 4294967295]"
            ))
        }),
        None => Ok(None),
    }
}

extendr_module! {
    mod receiver;
    fn print_image;
    fn terminal_size;
    fn fit_terminal_cells;
}

#[cfg(test)]
#[path = "../tests/receiver_test.rs"]
mod tests;
