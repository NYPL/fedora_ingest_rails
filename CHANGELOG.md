# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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