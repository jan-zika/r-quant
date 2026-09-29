# cache.R - per-symbol local CSV cache for price and FRED-series data.
#
# One CSV per symbol under data/cache/raw/prices/<SYMBOL>.csv and one per FRED
# series under data/cache/raw/macro/<SERIES>.csv. Writes are atomic
# (temp file + rename) and de-duplicated on date.
#
# NOTE: Yahoo Finance restates the `adjusted` column retroactively whenever a
# dividend or split occurs, so an incremental append is NOT strictly correct for
# `adjusted` over long horizons. Run update_market_data(full_refresh = TRUE)
# periodically to re-baseline. Raw OHLC/volume are append-safe.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

price_cache_path <- function(symbol) file.path(prices_dir(), paste0(symbol, ".csv"))

# Latest date already cached for a symbol, or NA if no cache exists.
last_cached_date <- function(symbol) {
  path <- price_cache_path(symbol)
  if (!file.exists(path)) return(as.Date(NA))
  df <- suppressMessages(readr::read_csv(path, show_col_types = FALSE))
  if (nrow(df) == 0 || !"date" %in% names(df)) return(as.Date(NA))
  max(as.Date(df$date), na.rm = TRUE)
}

read_cache <- function(symbol) {
  path <- price_cache_path(symbol)
  if (!file.exists(path)) return(NULL)
  df <- suppressMessages(readr::read_csv(path, show_col_types = FALSE))
  df$date <- as.Date(df$date)
  df
}

# Merge new rows into the cache: de-dup on date (new rows win), sort, atomic write.
write_cache <- function(symbol, new_df) {
  ensure_dirs()
  path <- price_cache_path(symbol)
  existing <- read_cache(symbol)

  combined <- if (is.null(existing)) {
    new_df
  } else {
    # New rows win on duplicate dates (they carry restated `adjusted`).
    dplyr::bind_rows(new_df, existing) |>
      dplyr::distinct(date, .keep_all = TRUE)
  }
  combined <- combined |> dplyr::arrange(date)

  tmp <- paste0(path, ".partial")
  readr::write_csv(combined, tmp)
  if (file.exists(path)) file.remove(path)
  file.rename(tmp, path)
  invisible(combined)
}

# --- FRED-series cache (one file per series) -------------------------------

macro_cache_path <- function(series) file.path(macro_dir(), paste0(series, ".csv"))

last_cached_macro_date <- function(series) {
  path <- macro_cache_path(series)
  if (!file.exists(path)) return(as.Date(NA))
  df <- suppressMessages(readr::read_csv(path, show_col_types = FALSE))
  if (nrow(df) == 0) return(as.Date(NA))
  max(as.Date(df$date), na.rm = TRUE)
}

read_macro_cache <- function(series) {
  path <- macro_cache_path(series)
  if (!file.exists(path)) return(NULL)
  df <- suppressMessages(readr::read_csv(path, show_col_types = FALSE))
  df$date <- as.Date(df$date)
  df
}

write_macro_cache <- function(series, new_df) {
  ensure_dirs()
  path <- macro_cache_path(series)
  existing <- read_macro_cache(series)

  combined <- if (is.null(existing)) new_df else {
    dplyr::bind_rows(new_df, existing) |> dplyr::distinct(date, .keep_all = TRUE)
  }
  combined <- combined |> dplyr::arrange(date)

  tmp <- paste0(path, ".partial")
  readr::write_csv(combined, tmp)
  if (file.exists(path)) file.remove(path)
  file.rename(tmp, path)
  invisible(combined)
}
