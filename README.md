<!-- README.md is generated from README.Rmd. Please edit that file -->

# rviuer

<!-- badges: start -->

[![Lifecycle:experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN-status](https://www.r-pkg.org/badges/version/rviuer)](https://CRAN.R-project.org/package=rviuer)
[![extendr](https://img.shields.io/badge/extendr-%5E0.9.0-276DC2)](https://extendr.github.io/extendr/extendr_api/)
[![Codecov test
coverage](https://codecov.io/gh/Exceret/rviuer/graph/badge.svg)](https://app.codecov.io/gh/Exceret/rviuer)
[![R-CMD-check](https://github.com/Exceret/rviuer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Exceret/rviuer/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of rviuer is to provide a tool to show the plot in R session
(and to practice my Rust coding skills 🦀).

## Installation

You can install the development version of rviuer from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("Exceret/rviuer")
```

## Exmaple

You can use `capture_plot` to capture the plot (In theory, any format
works, including `ggplot2`) in R session.

``` r
library(rviuer)
draw_pixels("rviuer") |>
  capture_plot(width = 50, height = 20) |>
  render_plot()
```

You can also use file path directly.

``` r
url <- "https://raw.githubusercontent.com/tidyverse/dplyr/main/man/figures/logo.png"
tmp <- tempdir()
dest <- file.path(tmp, "logo.png")

download.file(url, destfile = dest, mode = "wb")
render_plot(dest)
```

## Vignettes

- [Example](vignettes/example.Rmd)

## Related tools

MIT @ [viuer](https://github.com/atanunq/viuer)
