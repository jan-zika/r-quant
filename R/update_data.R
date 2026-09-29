# update_data.R - update the local market-data cache from the source APIs.
#
#   - Interactive:  source("R/update_data.R"); update_market_data()
#   - Headless:     Rscript R/update_data.R [--full]
#
# It (1) fetches latest prices for every symbol in config/symbols.yml plus the
# configured FRED macro series, (2) writes/updates the local CSV cache
# (incremental by default), and (3) builds processed artifacts the labs load
# directly: prices_wide.csv, returns_long.csv, macro_wide.csv.

# Resolve this file's directory so sourcing works from anywhere.
.this_dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE)),
                      error = function(e) "R")
for (f in c("config.R", "cache.R", "fetch_prices.R", "fetch_macro.R", "returns.R")) {
  source(file.path(.this_dir, f))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

# --- Main entry point ------------------------------------------------------

update_market_data <- function(full_refresh = FALSE, build_processed = TRUE) {
  cfg <- load_config()
  ensure_dirs()
  syms <- config_symbols(cfg)
  macro_series <- config_macro_series(cfg)
  start_date <- as.Date(cfg$start_date)
  today <- Sys.Date()

  cat(sprintf("Market data update | %d symbols + %d macro series | full_refresh=%s\n",
              length(syms), length(macro_series), full_refresh))
  cat(strrep("=", 50), "\n")

  ok <- character(0); failed <- character(0); skipped <- character(0)

  for (s in syms) {
    has_cache <- !is.na(last_cached_date(s))
    from <- if (full_refresh || !has_cache) start_date else last_cached_date(s) + 1

    if (!full_refresh && has_cache && from > today) {
      cat(sprintf("  %-12s up to date\n", s)); skipped <- c(skipped, s); next
    }

    df <- fetch_symbol(s, from = from, to = today)
    if (is.null(df) || nrow(df) == 0) {
      if (has_cache) {
        cat(sprintf("  %-12s up to date\n", s)); skipped <- c(skipped, s)
      } else {
        cat(sprintf("  %-12s FAILED (no data)\n", s)); failed <- c(failed, s)
      }
      next
    }
    write_cache(s, df)
    cat(sprintf("  %-12s %d rows (from %s)\n", s, nrow(df), from))
    ok <- c(ok, s)
  }

  # --- FRED macro series ---
  for (series in macro_series) {
    has_cache <- !is.na(last_cached_macro_date(series))
    from <- if (full_refresh || !has_cache) start_date else last_cached_macro_date(series) + 1

    if (!full_refresh && has_cache && from > today) {
      cat(sprintf("  %-12s up to date\n", series)); next
    }

    mdf <- fetch_fred_series(series, from = from, to = today)
    if (!is.null(mdf) && nrow(mdf) > 0) {
      write_macro_cache(series, mdf)
      cat(sprintf("  %-12s %d rows (FRED)\n", series, nrow(mdf)))
    } else {
      cat(sprintf("  %-12s no new data\n", series))
    }
  }

  cat(strrep("=", 50), "\n")
  cat(sprintf("Done: %d updated, %d up-to-date, %d failed.\n",
              length(ok), length(skipped), length(failed)))
  if (length(failed)) cat("  Failed:", paste(failed, collapse = ", "), "\n")

  if (build_processed) build_processed_artifacts(cfg)

  invisible(list(ok = ok, skipped = skipped, failed = failed))
}

# --- Processed artifacts ---------------------------------------------------

# Reads all cached symbols + macro series, joins group metadata, and writes:
#   data/cache/processed/prices_wide.csv   - adjusted close, one column per symbol
#   data/cache/processed/returns_long.csv  - date, symbol, group, daily/simple return
#   data/cache/processed/macro_wide.csv    - one column per FRED series (raw value)
build_processed_artifacts <- function(cfg = load_config()) {
  syms_meta <- cfg$symbols_df
  all_prices <- list()
  for (s in syms_meta$symbol) {
    df <- read_cache(s)
    if (!is.null(df)) all_prices[[s]] <- df
  }
  if (length(all_prices)) {
    prices <- dplyr::bind_rows(all_prices)

    # Wide adjusted-close panel.
    wide <- prices |>
      dplyr::select(date, symbol, adjusted) |>
      tidyr::pivot_wider(names_from = symbol, values_from = adjusted) |>
      dplyr::arrange(date)
    readr::write_csv(wide, file.path(processed_dir(), "prices_wide.csv"))

    # Long returns with group labels.
    returns_long <- compute_returns(prices) |>
      dplyr::left_join(syms_meta, by = "symbol") |>
      dplyr::select(date, symbol, name, group, simple_return, daily_return) |>
      dplyr::arrange(symbol, date)
    readr::write_csv(returns_long, file.path(processed_dir(), "returns_long.csv"))

    cat(sprintf("Processed: prices_wide.csv (%d rows), returns_long.csv (%d rows)\n",
                nrow(wide), nrow(returns_long)))
  } else {
    cat("No cached prices; skipping price artifacts.\n")
  }

  # Wide macro panel: one column per FRED series.
  macro_series <- config_macro_series(cfg)
  all_macro <- list()
  for (series in macro_series) {
    df <- read_macro_cache(series)
    if (!is.null(df)) all_macro[[series]] <- df
  }
  if (length(all_macro)) {
    macro_wide <- dplyr::bind_rows(all_macro) |>
      tidyr::pivot_wider(names_from = series_id, values_from = value) |>
      dplyr::arrange(date)
    readr::write_csv(macro_wide, file.path(processed_dir(), "macro_wide.csv"))
    cat(sprintf("Processed: macro_wide.csv (%d rows, %d series)\n",
                nrow(macro_wide), length(all_macro)))
  } else {
    cat("No cached macro series; skipping macro artifact.\n")
  }

  invisible(TRUE)
}

# --- CLI entry -------------------------------------------------------------

if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 0 || !interactive()) {
    update_market_data(full_refresh = "--full" %in% args)
  }
}
