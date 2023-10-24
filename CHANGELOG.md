# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Updated
- Merges to qa branch deploy to migrated and unmigrated environments. (DR-2597)

## [1.0.10] - 2023-10-12

### Fixed
- Fixed issue where parent records were not getting deleted from solr if empty. (DR-2342)
- Fixed issue where suppressed captures were not being pulled back from solr. (DR-2470)

## [1.0.9] - 2023-07-20

### Updated
- Added additional rights statements that release high resolution permalinks (DR-2396)

## [1.0.8] - 2023-07-05

### Fixed
- Fixed exception resulting from string responses that would end up as single hashes in conversion to json. (DR-2399)

## [1.0.7] - 2023-07-05

### Removed
- Removed references to solr 3.5. (DR-2309)

## [1.0.6] - 2023-06-07

### Added
- Accurately record first index date in repo api. (DR-2269)
- Create changelog endpoint. (DR-2370)

### Fixed
- Removed hierarchicalgeographic_mtxt from repoapi docs. (DR-2206)

### Updated
- Moved OCR data from the Fedora server to S3. (DR-2302)

## [1.0.5] - 2022-10-26

### Added
- Added new endpoint to respond with capture status. (DR-2075)

## [1.0.4] - 2022-09-09

### Updated
- Updated list of fields that should be forced into single values. (DR-1963)

## [1.0.3] - 2022-08-11

### Updated
- Turned indexing on for permalinks. (DR-1953)

## [1.0.2] - 2022-06-03

### Updated
- Updated travis keys. (DR-1708)
- Updated gems based on dependabot. (NA)
- Updated ingest to add value for hasOCR. (DR-1897)
- Updated ingest to add value for captureText_ocrtext. (DR-1895)

## [1.0.1] - 2021-09-20

### Added
- New method to get mets_alto during ingest for indexing. (DR-1459)

### Changed
- Changed parsing of solr docs to ensure single values. (DR-1459)

### Updated
- Updated gemfile with security fixes. (NA)

## [1.0.0] - 2021-04-21

### Added
- Added CHANGELOG.md. 
- Added new Repo Solr Client model to update repo api solr core when updates come through ingest. (DR-1059)

### Changed
- Upgraded postgres version. 
