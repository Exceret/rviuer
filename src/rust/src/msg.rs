use extendr_api::prelude::*;
use owo_colors::OwoColorize;

pub fn alert_warning(msg: &str, color: bool) -> () {
    let formated_msg = if color {
        format!("{} {}", "!".yellow().bold(), msg)
    } else {
        format!("! {}", msg)
    };
    extendr_api::reprintln!("{}", formated_msg);
}
// extendr: reprintln!("{}", alert_warning("something odd", use_color));
