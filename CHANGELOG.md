# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `CODEOWNERS` file
- Added AK and HI as regions for time series (N. Thomas 10/31/24)
- Added PRECTOTCORR as variable for annual cycle plots (N. Thomas 3/21/25)

### Changed

- Clean up of initial setup by A. Collow
- Widened plots so that y-axis is not cut off with multiple decimal points (N. Thomas 11/4/24)
- The climatology period was updated to 1980-2024 for the annual cycle time series plots (A. Collow 1/23/25)

### Fixed

- Fixed CDD constant 0 issue in computeRindices_seas.py (N. Thomas 11/22/24)
- Removed minus sign for lon2 in the yaml section of the global and global land plots

### Removed

- Codes that are not needed for the monthly workflow.

### Deprecated

