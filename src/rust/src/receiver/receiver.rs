//
use extendr_api::{
    extendr, extendr_module, Error, List, Nullable, Raw, Result, Robj, Rstr, Rtype, Types,
};
use viuer::Config;

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
/// @keywords internal
#[extendr]
fn print_image(
    config: List,
    #[extendr(default = "NULL")] file_path: Nullable<Rstr>,
    #[extendr(default = "NULL")] raw: Nullable<Raw>,
) -> Result<()> {
    Receiver::new(config, receiver_type_from_r(file_path, raw)?)?.print()
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
    fn new(config: List, receiver_type: ReceiverType) -> Result<Self> {
        Ok(Self {
            config: config_from_list(&config)?,
            receiver_type,
        })
    }

    /// Print the image described by `receiver_type`.
    ///
    /// The receiver is consumed so the owned [`Raw`] handle stays alive while
    /// the image is decoded: `raw.as_slice()` borrows from it, so the borrow
    /// lives no longer than this call and no bytes are copied.
    fn print(self) -> Result<()> {
        let Self {
            config,
            receiver_type,
        } = self;

        match receiver_type {
            ReceiverType::FromRaw(raw) => Self::print_from_raw(&config, raw.as_slice()),
            ReceiverType::FromFilePath(file_path) => Self::print_from_str(&config, &file_path),
        }
    }

    /// Print a PNG-encoded byte buffer.
    fn print_from_raw(config: &Config, raw: &[u8]) -> Result<()> {
        let image = image::load_from_memory_with_format(raw, image::ImageFormat::Png)
            .map_err(|err| Error::Other(format!("Image decoding failed: {err}")))?;

        viuer::print(&image, config)
            .map_err(|err| Error::Other(format!("Image printing failed: {err}")))?;

        Ok(())
    }

    /// Print the image stored at `file_path`.
    fn print_from_str(config: &Config, file_path: &str) -> Result<()> {
        viuer::print_from_file(file_path, config)
            .map_err(|err| Error::Other(format!("Image printing failed: {err}")))?;

        Ok(())
    }
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
        // `Config::use_sixel` only exists when the `sixel` feature is enabled,
        // so the option is ignored otherwise and its default (`true`) is
        // spelled out instead of read from `default`.
        #[cfg(feature = "sixel")]
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
}
