---
name: oci-data-pipeline
description: >
  Sets up a complete OCI Object Storage data pipeline for any data project.
  Use when the user says "set up OCI data pipeline," "add OCI caching," or
  needs a reproducible data layer that keeps large/changing data out of git.
  Handles directory scaffolding, .gitignore, secrets, Python upload helpers,
  language-appropriate ensure_data() consumers, manifest generation,
  incremental update, and full refresh.
---

# OCI Data Pipeline

## Purpose

This skill instructs the agent to scaffold and implement a **complete,
production-ready data pipeline** backed by Oracle Cloud Infrastructure (OCI)
Object Storage. The pipeline keeps data **out of git** while making it
**trivially reproducible** for any consumer (teammates, graders, CI) to
download the exact same data with a single function call.

The pipeline has two sides:

| Role | Who | What they run | Needs OCI SDK? |
|------|-----|---------------|----------------|
| **Maintainer** (producer) | Project owner | `scripts/oci_upload.py` | Yes (`pip install oci` + `~/.oci/config`) |
| **Consumer** | Anyone who clones | `ensure_data()` | No — uses only the public PAR URL |

## When to Use This Skill

Use this skill when:

- The project fetches data from APIs (financial, government, geospatial, etc.)
- Data files are too large to commit to git (> 1 MB per file, or > 10 MB total)
- Data changes over time and needs incremental or full refresh capability
- Multiple people need identical data without each running API calls
- Statistical reproducibility requires a fixed, hash-verified data snapshot
- The user says anything like:
  - "Set up OCI data pipeline"
  - "Add OCI caching to this project"
  - "Make my data reproducible without committing it"
  - "Set up data storage for my project"

## Statistical Focus

This skill exists because **data integrity is a prerequisite for sound
statistical inference**:

1. **Reproducibility** — Two researchers running the same analysis must get
   identical results. A committed manifest with SHA-256 hashes ensures every
   consumer downloads byte-identical files.

2. **API drift prevention** — APIs return different data on different days
   (new records, restated values, changed schemas). Separating data collection
   from analysis via a cached snapshot prevents "moving window" bias where
   statistical tests silently change their input.

3. **Auditability** — The `oci_manifest.json` is committed to git, creating a
   permanent record of exactly which files (with exact sizes and hashes) were
   used for any analysis at any point in the project's history.

4. **Data integrity** — SHA-256 verification after every download catches
   corruption before it can silently bias statistical results.

## Instructions for the Agent

### Step 1: Detect Project Language and Structure

Examine the repository for markers:

- **R project**: Look for `.R` files, `.Rproj`, `DESCRIPTION`, `.Renviron`, Quarto `.qmd` files
- **Python project**: Look for `pyproject.toml`, `requirements.txt`, `setup.py`, `.py` files
- **Mixed**: Both present — create helpers for both languages

Identify the project name (from `pyproject.toml`, directory name, or ask the user).

### Step 2: Create the `data/` Directory Structure

```
data/
├── README.md              # Committed — documents what lives where
├── oci_manifest.json      # Committed — file list + SHA-256 hashes + PAR URL
├── raw/                   # Gitignored — source data files from APIs/downloads
├── processed/             # Gitignored — derived/transformed artifacts
└── _archive/              # Gitignored — local-only scratch data, old versions
```

For **R projects** that use a `cache/` subdirectory pattern (like r-lab-sampling-bias):

```
data/
├── README.md              # Committed
├── oci_manifest.json      # Committed
└── cache/                 # Gitignored — everything below is disposable
    ├── raw/
    │   ├── prices/        # One CSV per symbol
    │   └── rates/         # Risk-free rate CSVs
    └── processed/         # Analysis-ready files (returns_long.csv, etc.)
```

The key rule: **only `data/README.md` and `data/oci_manifest.json` are committed**.
Everything else under `data/` is gitignored and re-downloadable.

### Step 3: Write `data/README.md`

Create a README that documents:

1. That data files are NOT stored in git — they live on OCI and are downloaded automatically
2. Quick start command to get data (`ensure_data()` call)
3. Folder structure showing what lives where
4. A table showing what's in Git vs OCI vs Local Only
5. OCI configuration details (bucket name, region, PAR URL env var)
6. How to update data (for maintainers)
7. Original data sources and their URLs

Use this template (adapt to the project):

```markdown
# Data Directory

Data files are **not stored in this repository**. They are hosted on Oracle Cloud
Infrastructure (OCI) Object Storage and downloaded automatically on first run.

## Quick Start

[Language-appropriate ensure_data() call]

## Folder Structure

[Directory tree]

## What's in Git vs OCI vs Local Only

| Location | Contents |
|---|---|
| **Git** | `oci_manifest.json`, `README.md` |
| **OCI bucket** | All of `raw/` + `processed/` |
| **Local only** | `_archive/`, `_notes/` |

## OCI Configuration

- **Bucket**: `<project>-data` (<region>)
- **Access**: Pre-Authenticated Request (read-only, no credentials needed)
- **PAR URL**: Embedded in `oci_manifest.json`, or set via `<PROJECT>_OCI_PAR_URL` env var

## Updating Data

[Maintainer instructions]

## Original Data Sources

[Table of sources with URLs]
```

### Step 4: Configure `.gitignore`

Add these entries to the project's `.gitignore` (merge with existing entries):

```gitignore
# Data files — too large for git, hosted on OCI Object Storage.
# Only the manifest and README are committed.
data/raw/
data/processed/
data/interim/
data/_archive/
data/_notes/
data/cache/

# Keep manifest and README committed (negative ignores)
!data/oci_manifest.json
!data/README.md

# Download partials
*.partial

# Secrets
.env
.Renviron
```

### Step 5: Create Secrets Template

**For Python projects** — create `.env.example`:

```bash
# Copy to .env (gitignored) and fill in your values.

# OCI Pre-Authenticated Request URL for downloading cached data.
# Read-only PAR, ending in /o/. Used by ensure_data().
<PROJECT>_OCI_PAR_URL=https://objectstorage.<region>.oraclecloud.com/p/<token>/n/<namespace>/b/<bucket>/o/

# API keys for data sources (if applicable)
# API_KEY=your_key_here
```

**For R projects** — create `.Renviron.example`:

```bash
# Copy this file to .Renviron (which is gitignored) and fill in your values.
# R reads .Renviron automatically at startup.

# OCI Pre-Authenticated Request (PAR) URL prefix for downloading cached data.
# Read-only PAR to the data bucket, ending in /o/. Used by R/ensure_data.R.
<PROJECT>_OCI_PAR_URL=https://objectstorage.<region>.oraclecloud.com/p/<token>/n/<namespace>/b/<bucket>/o/

# API keys for data sources (if applicable)
# FRED_API_KEY=your_fred_api_key_here
```

### Step 6: Create `scripts/oci_upload.py` — Maintainer Upload Tool

This is the **producer-side** tool. It requires `pip install oci` and a valid
`~/.oci/config`. Create this file with these functions:

```python
"""
OCI Object Storage upload script for <PROJECT>.

Uploads local data files to an OCI bucket and generates oci_manifest.json.
Requires the OCI Python SDK (pip install oci) and a valid ~/.oci/config.

Usage
-----
    # Dry run — list files without uploading (still generates manifest)
    python scripts/oci_upload.py --dry-run --par-url "<PAR_URL>"

    # Upload all data to OCI
    python scripts/oci_upload.py --par-url "<PAR_URL>"

    # Force re-upload all files (skip size-match check)
    python scripts/oci_upload.py --force --par-url "<PAR_URL>"
"""
```

**Required functions in `oci_upload.py`:**

| Function | Purpose |
|----------|---------|
| `sha256_file(path: Path) -> str` | Compute SHA-256 hex digest of a file in binary mode (`"rb"`, 64 KB chunks) |
| `guess_content_type(path: Path) -> str` | Map file extensions to MIME types (`.csv` → `text/csv`, `.parquet` → `application/octet-stream`, etc.) |
| `collect_files(data_dir: Path) -> list[dict]` | Walk the data directory, skip excluded dirs/files (`__pycache__`, `.DS_Store`, `README.md`, `oci_manifest.json`), return `[{key, local_path, size}]` |
| `upload_files(entries, bucket_name, namespace, client, par_url, force, dry_run) -> list[dict]` | Upload each file to OCI. Skip if remote size matches (unless `--force`). Return manifest entries `[{key, size, sha256}]` |
| `write_manifest(data_dir, manifest_files, par_url) -> Path` | Write `oci_manifest.json` with version, par_url_env_var, par_url_default, generated_at timestamp, and files list |
| `main()` | CLI with argparse: `--bucket`, `--profile`, `--par-url`, `--dry-run`, `--force`, `--data-dir` |

**Skip lists for `collect_files()`:**

```python
SKIP_DIRS  = {"_archive", "_notes", "_test", "__pycache__", ".ipynb_checkpoints"}
SKIP_FILES = {".gitkeep", ".DS_Store", "Thumbs.db", "README.md"}
```

**Manifest format (`oci_manifest.json`):**

```json
{
  "version": 1,
  "par_url_env_var": "<PROJECT>_OCI_PAR_URL",
  "par_url_default": "https://objectstorage.<region>.oraclecloud.com/p/.../o/",
  "generated_at": "2026-06-09T22:00:00+00:00",
  "files": [
    {"key": "raw/prices/XLK.csv", "size": 123456, "sha256": "abc123..."}
  ]
}
```

### Step 7: Create Consumer-Side `ensure_data()` Function

This is what consumers call. **No OCI SDK needed** — it uses only the public
PAR URL embedded in the manifest.

#### For Python projects — `src/<project>/data/fetch.py`:

**Required functions:**

| Function | Purpose |
|----------|---------|
| `ensure_data(data_dir, par_url, force, quiet) -> Path` | Main entry point. Load manifest, check local files, download missing ones, return data_dir |
| `_find_repo_root() -> Path` | Walk up from this file to find `pyproject.toml` |
| `_load_manifest(data_dir: Path) -> dict` | Parse `data/oci_manifest.json` |
| `_resolve_par_url(manifest, par_url) -> str` | Resolution chain: explicit arg → env var (from manifest `par_url_env_var`) → manifest `par_url_default` |
| `_check_file(local_path, expected_size) -> bool` | Fast existence + size check |
| `_sha256_file(path: Path) -> str` | Binary-mode SHA-256 digest |
| `_fmt_size(n_bytes: int) -> str` | Human-readable size string (KB/MB/GB) |
| `_progress_bar(current, total, width) -> str` | Text progress bar for download feedback |
| `_download_file(url, local_path, expected_size, expected_sha256, quiet, _retry) -> None` | Download with: atomic write (`.partial` → rename), progress bar, SHA-256 verification, one automatic retry on hash mismatch |

**Key design rules:**
- Downloads go to `<path>.partial` first, renamed only after hash verification
- SHA-256 is computed streaming during download (no re-read)
- On hash mismatch: delete partial, retry once, then raise `RuntimeError`
- HTTP errors produce clear messages mentioning PAR URL expiry
- Uses only `urllib` — no `requests` dependency needed

#### For R projects — `R/ensure_data.R`:

**Required functions:**

| Function | Purpose |
|----------|---------|
| `ensure_data(par_url, force, quiet)` | Main entry. Reads manifest, downloads missing files, verifies SHA-256 |
| `.resolve_par_url(manifest, par_url)` | Same resolution chain as Python |
| `.sha256_file(path)` | Binary-mode SHA-256 via `openssl::sha256()`. Must use `readBin()`, NOT text-mode read (CRLF on Windows breaks hashes) |
| `.download_one(url, dest, expected_size, expected_sha256, quiet)` | Download one file: `download.file(..., mode = "wb")` to `.partial`, verify hash, rename |

**Dependencies:** `jsonlite`, `openssl` (both on CRAN).

### Step 8: Create Data Update / Refresh Tool (if project has API sources)

#### For R projects — `R/update_data.R`:

Provides `update_market_data(full_refresh, upload, build_processed)`:

1. **Incremental update** (default): For each symbol, check `last_cached_date()`,
   fetch only new dates from the API, merge into existing CSV cache
2. **Full refresh** (`--full`): Re-fetch all data from `start_date` to today,
   replacing the entire cache (needed when APIs restate historical values)
3. **Build processed artifacts**: After fetching, derive analysis-ready files
   (e.g., `returns_long.csv` from raw price CSVs)
4. **Upload to OCI** (`--upload`): Shell out to `python scripts/oci_upload.py`

CLI usage: `Rscript R/update_data.R [--full] [--upload]`

#### For Python projects:

Same pattern — a `scripts/update_data.py` or module function that:
1. Reads config for the data source list
2. Fetches new data from each source (incremental or full)
3. Writes to `data/raw/`
4. Processes into `data/processed/`
5. Optionally calls `oci_upload.py`

### Step 9: Initialize or Verify `oci_manifest.json`

If no data files exist yet, create a minimal manifest:

```json
{
  "version": 1,
  "par_url_env_var": "<PROJECT>_OCI_PAR_URL",
  "par_url_default": "",
  "generated_at": "",
  "files": []
}
```

If data files exist locally, instruct the user to run:

```bash
python scripts/oci_upload.py --dry-run --par-url "<PAR_URL>"
```

This generates the manifest from local files without uploading. The user can
then upload when ready.

## Common Mistakes to Avoid

| Mistake | Why It Matters | Prevention |
|---------|---------------|------------|
| Committing data files to git | Repository bloat, large file conflicts, slow clones | `.gitignore` entries for `data/raw/`, `data/processed/`, `data/cache/` |
| Committing `.env` / `.Renviron` | Leaks API keys and PAR URLs (security risk) | `.gitignore` entry + `.example` template committed instead |
| Running statistical tests on live API data | Results change between runs — impossible to reproduce p-values | Always use `ensure_data()` to work from a fixed cache |
| Forgetting to commit updated `oci_manifest.json` | Consumers can't download new/updated files | Remind after upload: `git add data/oci_manifest.json` |
| Using text mode for SHA-256 hashing | CRLF ↔ LF translation on Windows silently changes the hash | Always read in binary mode: Python `open(path, "rb")`, R `readBin()` |
| Hardcoding PAR URLs in source code | PAR URLs expire and can't be rotated without code changes | Use env var → manifest default resolution chain |
| Skipping hash verification after download | Corrupted or truncated downloads silently bias statistical analysis | Always verify SHA-256 before renaming `.partial` → final |
| Not using atomic writes (`.partial` pattern) | Interrupted downloads leave corrupt files that pass size checks | Write to `.partial` first, rename only after hash verification |
| Ignoring `oci_manifest.json` in `.gitignore` | Consumers have no way to know what files to download | Use negative ignore: `!data/oci_manifest.json` |

## Final Output Expectations

After the agent completes this skill, the project should have:

1. ✅ A `data/` directory with `README.md` documenting the pipeline
2. ✅ A `.gitignore` that ignores data files but commits the manifest
3. ✅ A secrets template (`.env.example` or `.Renviron.example`)
4. ✅ A `scripts/oci_upload.py` with `--dry-run`, `--force`, `--par-url` CLI
5. ✅ A language-appropriate `ensure_data()` function for consumers
6. ✅ An `oci_manifest.json` (empty or populated from existing data)
7. ✅ A data update/refresh tool if the project has API data sources
8. ✅ A status report confirming the scaffolding is complete and listing next steps

## Example Use Cases

**Example 1: New R project with API data**

> User: "Set up OCI data pipeline for my R project that pulls FRED and Yahoo
> Finance data"
>
> Agent: Creates `R/config.R`, `R/cache.R`, `R/ensure_data.R`,
> `R/update_data.R`, `scripts/oci_upload.py`, `data/README.md`, configures
> `.gitignore` and `.Renviron.example`, generates empty manifest.

**Example 2: Existing Python project needs caching**

> User: "Add OCI caching to my existing Python data science project at
> src/aigv_pjm/"
>
> Agent: Creates `src/aigv_pjm/data/fetch.py` with `ensure_data()`,
> `scripts/oci_upload.py`, `data/README.md`, updates `.gitignore`, creates
> `.env.example`. Runs `--dry-run` to generate manifest from existing data
> files.

**Example 3: Consumer setup**

> User: "I cloned this repo and there's no data. How do I get it?"
>
> Agent: Reads the manifest, identifies the PAR URL, runs `ensure_data()` to
> download all files, verifies hashes, reports status.
