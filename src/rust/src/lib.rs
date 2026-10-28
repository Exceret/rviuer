use extendr_api::prelude::*;

mod msg;
mod output;
mod receiver;
/// Vendored copy of the `viuer` crate; see the module docs.
mod viuer;

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod rviuer;
    use receiver;
}
