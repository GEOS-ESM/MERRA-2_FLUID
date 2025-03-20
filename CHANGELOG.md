# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `CODEOWNERS` file
- Added AK and HI as regions for time series (N. Thomas 10/31/24)
- Added PRECTOTCORR as a variable for the annual cycle plots (N. Thomas 3/20/25)

### Changed

- Clean up of initial setup by A. Collow
- Widened plots so that y-axis is not cut off with multiple decimal points (N. Thomas 11/4/24)
- Changed long name for precip in annual cycle plots (to model-generated precipitation) (N. Thomas 3/20/25)

### Fixed

- Fixed CDD constant 0 issue in computeRindices_seas.py (N. Thomas 11/22/24)

### Removed

- Codes that are not needed for the monthly workflow.

### Deprecated

