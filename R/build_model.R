# build_model.R - construct the factor model frame and report diagnostics.
# Exploratory: sources the pipeline, builds factors, fits lm() for each candidate
# target, and prints summary + VIF + DW so we can choose the ticker.

.this_dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE)),
                      error = function(e) "R")
source(file.path(.this_dir, "config.R"))

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr)
})

pw <- readr::read_csv(file.path(processed_dir(), "prices_wide.csv"), show_col_types = FALSE)
mw <- readr::read_csv(file.path(processed_dir(), "macro_wide.csv"), show_col_types = FALSE)

# Daily simple returns from adjusted-close wide panel.
rets <- pw |> arrange(date)
ret_cols <- setdiff(names(rets), "date")
for (c in ret_cols) rets[[c]] <- rets[[c]] / dplyr::lag(rets[[c]]) - 1
rets <- rets[-1, ]

# Macro: rf daily decimal; first differences of spreads/VIX for stationarity.
macro <- mw |> arrange(date) |>
  mutate(rf_daily = (DTB3 / 100) / 252,
         d_term   = T10Y3M - dplyr::lag(T10Y3M),
         d_credit = BAA10Y - dplyr::lag(BAA10Y),
         d_vix    = VIXCLS - dplyr::lag(VIXCLS)) |>
  select(date, rf_daily, d_term, d_credit, d_vix)

df <- rets |> inner_join(macro, by = "date") |>
  mutate(
    mkt_rf = VTI - rf_daily,                 # market excess return (CAPM anchor)
    size   = IWM - SPY,                      # small minus large
    value  = IWD - IWF,                      # value minus growth
    sector = XSD - VTI                       # semiconductor tilt over market
  )

cat("Rows after join:", nrow(df), "\n\n")

predictors <- c("mkt_rf", "size", "value", "sector", "d_term", "d_credit", "d_vix")

fit_one <- function(tkr) {
  d <- df |>
    mutate(y = .data[[tkr]] - rf_daily) |>
    select(y, all_of(predictors)) |>
    tidyr::drop_na()
  m <- lm(y ~ ., data = d)
  cat("=== ", tkr, " | N =", nrow(d), " ===\n")
  s <- summary(m)
  cat(sprintf("R2=%.3f  adjR2=%.3f\n", s$r.squared, s$adj.r.squared))
  print(round(s$coefficients, 5))
  cat("VIF:\n"); print(round(car::vif(m), 2))
  cat("Durbin-Watson resid autocorr (lag1):",
      round(cor(head(resid(m), -1), tail(resid(m), -1)), 3), "\n\n")
  invisible(m)
}

for (tkr in c("NVDA", "MU", "TSLA", "AAPL")) fit_one(tkr)
