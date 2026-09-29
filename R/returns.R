# returns.R - turn cached prices into returns, plus risk-metric helpers.

suppressPackageStartupMessages({
  library(dplyr)
})

# Daily simple and log returns from the adjusted close, per symbol.
# Input: tidy data.frame with date, symbol, adjusted.
compute_returns <- function(prices) {
  prices |>
    dplyr::arrange(symbol, date) |>
    dplyr::group_by(symbol) |>
    dplyr::mutate(
      simple_return = adjusted / dplyr::lag(adjusted) - 1,
      daily_return  = log(adjusted / dplyr::lag(adjusted))  # log return
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(daily_return))
}

# --- Risk metrics ----------------------------------------------------------

# Annualized Sharpe ratio from a vector of daily (log or simple) returns and a
# matching vector (or scalar) of daily risk-free rates. 252 trading days/year.
sharpe <- function(returns, rf_daily = 0, periods = 252) {
  excess <- returns - rf_daily
  excess <- excess[is.finite(excess)]
  if (length(excess) < 2) return(NA_real_)
  (mean(excess) / stats::sd(excess)) * sqrt(periods)
}

# Maximum drawdown from a return series (as a negative fraction).
max_drawdown <- function(returns) {
  returns <- returns[is.finite(returns)]
  if (!length(returns)) return(NA_real_)
  equity <- cumprod(1 + returns)
  peak <- cummax(equity)
  min(equity / peak - 1)
}

# Calmar ratio: annualized return / |max drawdown|.
calmar <- function(returns, periods = 252) {
  returns <- returns[is.finite(returns)]
  if (length(returns) < 2) return(NA_real_)
  ann_return <- mean(returns) * periods
  mdd <- max_drawdown(returns)
  if (is.na(mdd) || mdd == 0) return(NA_real_)
  ann_return / abs(mdd)
}
