use extendr_api::prelude::*;

mod msg;
mod receiver;

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod rviuer;
    use receiver;
}
