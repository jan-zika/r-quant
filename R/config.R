# config.R - configuration and path helpers for the market-data pipeline.
#
# Single place that knows where the repo lives, where data goes, and how to
# read config/symbols.yml plus the secrets in .Renviron.

suppressPackageStartupMessages({
  library(yaml)
})

# --- Repo root -------------------------------------------------------------

# Walk up from this file (or the working dir) to the directory containing
# config/symbols.yml. Works whether sourced from R/, labs/, or the repo root.
repo_root <- function() {
  this_file <- tryCatch(
    normalizePath(sys.frame(1)$ofile, mustWork = FALSE),
    error = function(e) NA_character_
  )
  start <- if (!is.na(this_file) && nzchar(this_file)) dirname(this_file) else getwd()
  cur <- normalizePath(start, mustWork = FALSE)
  for (i in seq_len(10)) {
    if (file.exists(file.path(cur, "config", "symbols.yml"))) return(cur)
    parent <- dirname(cur)
    if (parent == cur) break
    cur <- parent
  }
  stop("Could not locate repo root (config/symbols.yml). Set working dir to the repo.")
}

# --- Paths -----------------------------------------------------------------

# data/        - committed metadata only (README.md)
# data/cache/  - all downloaded/derived data; wholly gitignored (never committed)
data_dir      <- function() file.path(repo_root(), "data")
cache_dir     <- function() file.path(data_dir(), "cache")
raw_dir       <- function() file.path(cache_dir(), "raw")
prices_dir    <- function() file.path(raw_dir(), "prices")
rates_dir     <- function() file.path(raw_dir(), "rates")
macro_dir     <- function() file.path(raw_dir(), "macro")
processed_dir <- function() file.path(cache_dir(), "processed")

# Create the cache directory tree if it does not yet exist.
ensure_dirs <- function() {
  for (d in c(prices_dir(), rates_dir(), macro_dir(), processed_dir())) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(TRUE)
}

# --- Config ----------------------------------------------------------------

load_config <- function() {
  cfg <- yaml::read_yaml(file.path(repo_root(), "config", "symbols.yml"))
  # Flatten the symbols list into a data.frame for convenience.
  cfg$symbols_df <- do.call(rbind, lapply(cfg$symbols, function(s) {
    data.frame(symbol = s$symbol, name = s$name, group = s$group,
               stringsAsFactors = FALSE)
  }))
  cfg
}

config_symbols <- function(cfg = load_config()) cfg$symbols_df$symbol

# FRED series used as macro predictors (plus the risk-free rate). Returns a
# character vector; falls back to a sensible default if not set in the YAML.
config_macro_series <- function(cfg = load_config()) {
  s <- cfg$macro_series
  if (is.null(s) || !length(s)) {
    return(c("DTB3", "DGS10", "DGS3MO", "BAMLH0A0HYM2", "VIXCLS"))
  }
  unlist(s, use.names = FALSE)
}

# --- Secrets ---------------------------------------------------------------

# FRED key: prefer the environment (.Renviron -> FRED_API_KEY).
fred_api_key <- function() {
  key <- Sys.getenv("FRED_API_KEY", unset = "")
  if (!nzchar(key)) {
    stop("FRED_API_KEY not set. Add it to .Renviron (see .Renviron.example).")
  }
  key
}

# Tiingo key: optional. Returns "" when unset, so price fetching can fall back
# to the keyless Yahoo/Stooq sources.
tiingo_api_key <- function() Sys.getenv("TIINGO_API_KEY", unset = "")
