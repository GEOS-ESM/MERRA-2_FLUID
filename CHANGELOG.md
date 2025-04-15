# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Added PRECTOTCORR as variable for annual cycle plots (N. Thomas 3/21/25)
- Added Dry PM2.5 as a variable for annual cycle plots (A. Collow 3/28/25)
- Added GMAO logo and version number to annual cycle plots (A. Collow 3/28/25)
- Added region.yaml to be used with all versions of annual cylce plots
- Added Amin's percentile codes (4/15/25)

### Changed


### Fixed
- Fixed bug so that all annual cycle plot variables can be run with latestyear_spaghetti_ncaregions_testylim.py (N. Thomas 3/21/25)
- Fixed issue with region numbers in annual cycle plot codes (N. Thomas 3/24/25)

### Removed


### Deprecated



## [v1.0.0]

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
- Fixed bug so that all annual cycle plot variables can be run with latestyear_spaghetti_ncaregions_testylim.py (N. Thomas 3/21/25)
- Fixed issue with region numbers in annual cycle plot codes (N. Thomas 3/24/25)

### Removed

- Codes that are not needed for the monthly workflow.

### Deprecated

