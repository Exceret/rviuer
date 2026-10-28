use super::*;

#[test]
fn parse_accepts_both_channels() {
    assert_eq!(Output::parse("stderr").unwrap(), Output::Stderr);
    assert_eq!(Output::parse("stdout").unwrap(), Output::Stdout);
}

#[test]
fn parse_rejects_anything_else() {
    let err = Output::parse("console").unwrap_err().to_string();
    assert!(err.contains("\"console\""), "{err}");
    assert!(err.contains("stderr"), "{err}");
    assert!(err.contains("stdout"), "{err}");
}

#[test]
fn empty_payload_produces_no_batch() {
    assert!(split_batches(Vec::new()).is_empty());
}

#[test]
fn short_payload_is_one_batch() {
    assert_eq!(split_batches(b"abc".to_vec()), vec![b"abc".to_vec()]);
}

#[test]
fn nul_bytes_are_dropped() {
    assert_eq!(
        split_batches(b"a\0b\0\0c".to_vec()),
        vec![b"abc".to_vec()],
        "NUL bytes must not reach the C string"
    );
}

#[test]
fn payload_is_split_at_the_batch_size() {
    let payload = vec![b'x'; RConsoleWriter::MAX_BATCH + 3];
    let batches = split_batches(payload);

    assert_eq!(batches.len(), 2);
    assert_eq!(batches[0].len(), RConsoleWriter::MAX_BATCH);
    assert_eq!(batches[1], vec![b'x'; 3]);
}

#[test]
fn payload_of_exactly_one_batch_is_not_split() {
    let batches = split_batches(vec![b'x'; RConsoleWriter::MAX_BATCH]);

    assert_eq!(batches.len(), 1);
    assert_eq!(batches[0].len(), RConsoleWriter::MAX_BATCH);
}

#[test]
fn a_character_straddling_the_cut_opens_the_next_batch() {
    // "▀" is three bytes; it starts one byte before the cut
    let mut payload = vec![b'x'; RConsoleWriter::MAX_BATCH - 1];
    payload.extend_from_slice("▀".as_bytes());

    let batches = split_batches(payload);

    assert_eq!(batches.len(), 2);
    assert_eq!(batches[0], vec![b'x'; RConsoleWriter::MAX_BATCH - 1]);
    assert_eq!(batches[1], "▀".as_bytes());
}

#[test]
fn every_batch_of_a_multi_byte_payload_is_valid_utf8() {
    // the half blocks the image is drawn with, i.e. what R receives
    let payload: Vec<u8> = "▀▄".repeat(RConsoleWriter::MAX_BATCH).into_bytes();
    let expected_len = payload.len();

    let batches = split_batches(payload);

    assert!(batches.len() > 1, "the payload must be split");
    for batch in &batches {
        assert!(
            std::str::from_utf8(batch).is_ok(),
            "batch of {} bytes is not valid UTF-8",
            batch.len()
        );
        assert!(batch.len() <= RConsoleWriter::MAX_BATCH);
    }
    assert_eq!(batches.iter().map(Vec::len).sum::<usize>(), expected_len);
}

#[test]
fn payload_that_is_not_utf8_is_still_split() {
    let batches = split_batches(vec![0xFF; RConsoleWriter::MAX_BATCH + 1]);

    assert_eq!(batches.len(), 2);
    assert_eq!(batches[0].len(), RConsoleWriter::MAX_BATCH);
    assert_eq!(batches[1], vec![0xFF; 1]);
}
