# fetch_prices.R - download daily OHLCV price history for ETFs/stocks.
#
# Source chain (first that succeeds wins, per symbol):
#   1. Tiingo  - cleanest adjusted EOD, used only when TIINGO_API_KEY is set.
#   2. Yahoo   - tidyquant::tq_get, keyless.
#   3. Stooq   - keyless EOD fallback.
#
# Each symbol is fetched independently so one failure does not abort the run.
# All sources are normalized to: date, symbol, open, high, low, close, volume, adjusted.

suppressPackageStartupMessages({
  library(tidyquant)
  library(dplyr)
})

# --- Per-source fetchers ---------------------------------------------------

# Yahoo / Stooq via tidyquant. Returns a tidy data.frame or NULL.
.fetch_tidyquant <- function(symbol, from, to, source = "yahoo") {
  raw <- tryCatch(
    suppressWarnings(
      if (source == "yahoo") {
        tidyquant::tq_get(symbol, get = "stock.prices", from = from, to = to)
      } else {
        tidyquant::tq_get(symbol, get = "stock.prices", from = from, to = to,
                          source = "stooq")
      }
    ),
    error = function(e) {
      message(sprintf("    [%s] %s fetch error: %s", symbol, source, conditionMessage(e)))
      NULL
    }
  )
  .normalize_prices(raw, symbol)
}

# Tiingo via riingo. Returns a tidy data.frame or NULL. Requires TIINGO_API_KEY.
.fetch_tiingo <- function(symbol, from, to) {
  key <- tiingo_api_key()
  if (!nzchar(key)) return(NULL)
  if (!requireNamespace("riingo", quietly = TRUE)) {
    message("    riingo not installed; skipping Tiingo. install.packages('riingo')")
    return(NULL)
  }
  raw <- tryCatch({
    riingo::riingo_set_token(key)
    riingo::riingo_prices(symbol, start_date = as.Date(from), end_date = as.Date(to))
  }, error = function(e) {
    message(sprintf("    [%s] tiingo fetch error: %s", symbol, conditionMessage(e)))
    NULL
  })
  if (is.null(raw) || !is.data.frame(raw) || nrow(raw) == 0) return(NULL)

  # riingo columns: date, open, high, low, close, volume, adjClose, ... (+ ticker).
  # `date` is POSIXct; map adjClose -> adjusted and keep the standard set.
  out <- raw
  out$symbol   <- symbol
  out$date     <- as.Date(out$date)
  out$adjusted <- out$adjClose
  keep <- c("date", "symbol", "open", "high", "low", "close", "volume", "adjusted")
  keep <- keep[keep %in% names(out)]
  out <- out[, keep, drop = FALSE]
  dplyr::arrange(out, date)
}

# Normalize a tidyquant result (handles NULL / empty / all-NA windows).
.normalize_prices <- function(raw, symbol) {
  if (is.null(raw) || !is.data.frame(raw) || nrow(raw) == 0) return(NULL)
  if (!"date" %in% names(raw) || all(is.na(raw$date))) return(NULL)
  out <- raw
  if (!"symbol" %in% names(out)) out$symbol <- symbol
  keep <- c("date", "symbol", "open", "high", "low", "close", "volume", "adjusted")
  keep <- keep[keep %in% names(out)]
  out <- out[, keep, drop = FALSE]
  out$date <- as.Date(out$date)
  dplyr::arrange(out, date)
}

# --- Public API ------------------------------------------------------------

# Fetch one symbol, trying Tiingo (if keyed) -> Yahoo (with retry) -> Stooq.
fetch_symbol <- function(symbol, from, to = Sys.Date(), retries = 2L) {
  # 1. Tiingo (only attempted when a key is configured).
  res <- .fetch_tiingo(symbol, from, to)
  if (!is.null(res)) return(res)

  # 2. Yahoo with simple backoff.
  for (attempt in seq_len(retries)) {
    res <- .fetch_tidyquant(symbol, from, to, source = "yahoo")
    if (!is.null(res)) return(res)
    Sys.sleep(1.5 * attempt)
  }

  # 3. Stooq fallback.
  message(sprintf("    [%s] Yahoo failed after %d tries; trying Stooq.", symbol, retries))
  .fetch_tidyquant(symbol, from, to, source = "stooq")
}

# Fetch a vector of symbols, returning a named list of data.frames (NULL on fail).
fetch_prices <- function(symbols, from, to = Sys.Date()) {
  res <- list()
  for (s in symbols) {
    res[[s]] <- fetch_symbol(s, from = from, to = to)
  }
  res
}
