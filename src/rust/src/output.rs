//! Destination of the rendered image.
//!
//! The image, escape sequences included, is written to one of R's console
//! channels rather than to the process stdout. That follows the convention of
//! the cli package: ordinary output stays clean, so `capture.output()` does not
//! swallow the picture, while `sink(type = "message")` can capture or silence
//! it.
//!
//! The channel is [`Output::Stderr`] unless the R side asks for
//! [`Output::Stdout`].

use extendr_api::{Error, Result};

/// R console channel the image bytes are written to.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Output {
    /// R's message stream, written with `REprintf` (what `reprintln!` uses).
    Stderr,
    /// R's output stream, written with `Rprintf` (what `rprintln!` uses).
    Stdout,
}

impl Output {
    /// Value of the `output` argument that selects [`Output::Stderr`].
    pub const STDERR: &'static str = "stderr";
    /// Value of the `output` argument that selects [`Output::Stdout`].
    pub const STDOUT: &'static str = "stdout";

    /// Parse a channel name, as accepted by the `output` option.
    pub fn parse(value: &str) -> Result<Self> {
        match value {
            Self::STDERR => Ok(Self::Stderr),
            Self::STDOUT => Ok(Self::Stdout),
            other => Err(Error::Other(format!(
                "`output` must be \"{}\" or \"{}\", not \"{}\"",
                Self::STDERR,
                Self::STDOUT,
                other
            ))),
        }
    }

    /// Write one piece of the image to the channel.
    fn write_bytes(self, bytes: Vec<u8>) {
        match self {
            Self::Stderr => extendr_api::print_r_error(bytes),
            Self::Stdout => extendr_api::print_r_output(bytes),
        }
    }
}

/// [`std::io::Write`] adapter that forwards bytes to an R console channel.
///
/// The bytes are batched, because one console entry per pixel is not affordable.
/// A batch is released when it ends on a newline, which keeps a picture that is
/// written row by row flowing, or when it reaches
/// [`RConsoleWriter::MAX_BATCH`], which also bounds the size of the single long
/// payload of the iTerm and Kitty protocols (see `split_batches` for how it is
/// cut).
pub struct RConsoleWriter {
    output: Output,
    pending: Vec<u8>,
}

impl RConsoleWriter {
    /// Largest batch handed to R in one call, in bytes.
    ///
    /// R's console layer, and the editors that host R (Positron's ark reads the
    /// console 8 KiB at a time), move console output around in 8 KiB blocks.
    /// Staying below that keeps every batch inside a single block, and halving
    /// it makes a block boundary of two batches fall on a batch boundary rather
    /// than inside one.
    pub const MAX_BATCH: usize = 4 * 1024;

    /// Create a writer for `output`.
    pub fn new(output: Output) -> Self {
        Self {
            output,
            pending: Vec::new(),
        }
    }

    /// Send the pending bytes to R.
    fn emit(&mut self) {
        for batch in split_batches(std::mem::take(&mut self.pending)) {
            self.output.write_bytes(batch);
        }
    }
}

impl std::io::Write for RConsoleWriter {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        self.pending.extend_from_slice(buf);

        if self.pending.len() >= Self::MAX_BATCH || self.pending.last() == Some(&b'\n') {
            self.emit();
        }

        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        self.emit();
        Ok(())
    }
}

/// Split `payload` into the batches handed to R.
///
/// NUL bytes are dropped: they travel through a C string, so R would see the
/// rest of the payload as truncated (and `CString::new` panics on them). The
/// image never contains one, but the writer is the last place where a corrupted
/// payload could do harm.
///
/// A batch never ends in the middle of a multi-byte UTF-8 character. Each batch
/// becomes one `Rprintf` call, and the console driver of the host decodes every
/// chunk it receives as UTF-8: a chunk that stops after the first byte of a
/// three-byte `▀` is rejected, which in Positron aborts the whole R session
/// ("Failed to read from R buffer: Utf8Error"). The half blocks the image is
/// drawn with are multi-byte characters, so a cut at a fixed offset hits one
/// sooner or later.
fn split_batches(payload: Vec<u8>) -> Vec<Vec<u8>> {
    let mut cleaned: Vec<u8> = payload.into_iter().filter(|byte| *byte != 0).collect();

    if cleaned.is_empty() {
        return Vec::new();
    }

    if cleaned.len() <= RConsoleWriter::MAX_BATCH {
        return vec![cleaned];
    }

    let mut batches = Vec::with_capacity(cleaned.len().div_ceil(RConsoleWriter::MAX_BATCH));
    while cleaned.len() > RConsoleWriter::MAX_BATCH {
        let rest = cleaned.split_off(next_batch_start(&cleaned));
        batches.push(cleaned);
        cleaned = rest;
    }
    batches.push(cleaned);

    batches
}

/// Start of the batch that follows the one beginning at `bytes`.
///
/// That is [`RConsoleWriter::MAX_BATCH`] unless the offset lands inside a
/// multi-byte UTF-8 character, in which case the batch is shortened to the start
/// of the character, which then opens the next batch. A payload that is not
/// valid UTF-8 to begin with is cut at the fixed offset: there is no character
/// boundary to respect, and the split must still make progress.
fn next_batch_start(bytes: &[u8]) -> usize {
    let max = RConsoleWriter::MAX_BATCH.min(bytes.len());

    match std::str::from_utf8(&bytes[..max]) {
        Ok(_) => max,
        // `valid_up_to` is where the character cut in half starts; `None` as the
        // error length means the bytes are merely incomplete, not invalid.
        Err(err) => match err.error_len() {
            None if err.valid_up_to() > 0 => err.valid_up_to(),
            _ => max,
        },
    }
}

#[cfg(test)]
#[path = "tests/output_test.rs"]
mod tests;
