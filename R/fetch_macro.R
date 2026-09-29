# fetch_macro.R - download macroeconomic / risk-free series from FRED.
#
# Generalizes a single risk-free-rate pull into a multi-series fetcher. Each
# series is returned tidy (date, series_id, value) and cached independently, so
# one failure does not abort the run. The regression lab uses:
#
#   DTB3         3-Month Treasury Bill, Secondary Market Rate (risk-free rate)
#   DGS10        10-Year Treasury Constant Maturity yield
#   DGS3MO       3-Month Treasury Constant Maturity yield
#   BAMLH0A0HYM2 ICE BofA US High Yield Option-Adjusted Spread (credit stress)
#   VIXCLS       CBOE Volatility Index (VIX)
#
# All are quoted in percent (VIXCLS in index points); transformations into
# factors (excess returns, first differences) happen in the lab, not here.

suppressPackageStartupMessages({
  library(fredr)
  library(dplyr)
})

# Fetch a single FRED series. Returns date, series_id, value (or NULL on failure).
fetch_fred_series <- function(series, from, to = Sys.Date()) {
  fredr::fredr_set_key(fred_api_key())
  raw <- tryCatch(
    fredr::fredr(series_id = series,
                 observation_start = as.Date(from),
                 observation_end = as.Date(to)),
    error = function(e) {
      message(sprintf("    [%s] FRED fetch error: %s", series, conditionMessage(e)))
      NULL
    }
  )
  if (is.null(raw) || nrow(raw) == 0) return(NULL)

  raw |>
    dplyr::transmute(
      date = as.Date(date),
      series_id = series,
      value = value
    ) |>
    dplyr::arrange(date)
}

# Convenience kept for any risk-free-rate-specific use: DTB3 plus a daily decimal.
# date, dtb3_annual_pct, rf_daily (or NULL on failure).
fetch_risk_free <- function(from, to = Sys.Date(), series = "DTB3") {
  df <- fetch_fred_series(series, from = from, to = to)
  if (is.null(df)) return(NULL)
  df |>
    dplyr::transmute(
      date = date,
      dtb3_annual_pct = value,
      # Annualized percent -> approximate daily decimal rate (252 trading days).
      rf_daily = (value / 100) / 252
    )
}
