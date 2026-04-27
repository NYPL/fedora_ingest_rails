# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed logic that was skipping suppressed capture updates. (DR-4073)

## [3.3.1] - 2026-01-08

## Changed
- Fix Docker image builds (NO-REF)

## [3.3] - 2026-01-07

### Changed
- Add support for hocr. (DR-3923)

## [3.2.6] - 2025-10-16

### Changed
- Set suppressed to true if captures supprssed. (DR-3842)

## [3.2.5] - 2025-09-12

### Changed
- Revert precaching. (NO-REF)

## [3.2.4] - 2025-07-02

### Added
- Added precaching to ingest routine for captures and added a script for precaching targeted collections. (DR-3740)

## [3.2.3] - 2025-06-09

### Fixed
- Fixed issue where a final update was not happening for parent uuids. (DR-3678)

## [3.2.2] - 2025-04-30

### Added
- Added one-off script to update titles and dates. (DR-3577)

## [3.2.1] - 2025-04-03

### Added
- Added method to add containsUnrestrictedMaterial to solr docs. (DR-3425)

## [3.2.0] - 2025-03-25

### Updated
- Updated code to mint permalinks bound for IIIF/Cantaloupe instead of Fedora. (DR-3006)

## [3.1.0] - 2025-03-12

### Added
- Added one-off script to be run to cleanup links to Fedora. (DR-3042)

### Removed
- Removed Fedora integration (DR-3005)

### Updated
- Updated code to apply values to new fields. (DR-3334)

## [3.0.0] - 2024-09-16

### Added
- New one-off script to add dates where firstIndexed_dt is missing. (DR-2796)

### Updated
- Upgraded Ubuntu, Ruby, and Rails versions (TGR-48)
- Updated AWS keys (DR-3183)

## Fixed
- Fixed travis builds (TGR-104)

## [2.1.0] - 2024-04-15

### Added
- Added a new endpoint for sending updates for single field values. (DR-2775)
- Exposed delayed jobs through delayed job web. (DR-2830)
- Added firstIndexed_dt and dateIndexed_dt to repoapi solr docs. (DR-2789)

## [2.0.1] - 2024-01-16

### Fixed
- Fixed additional issue causing suppressed captures to be pulled in for indexing. (DR-2690)

### Added
- Added one-off script to cleanup empty collections and containers. (DR-2557)

### Updated
- Stopped deploying to legacy environments. (DR-2661)
- Updated travis deployer keys after rotation. (DR-2725)

## [2.0.0] - 2023-10-15

### Updated
- Merges to qa branch deploy to migrated and unmigrated environments. (DR-2597)
- Merges to production branch deploy to migrated and unmigrated environments. (DR-2599)

### Changed
- Moved production environment to nypl-dams-prod (DR-2601)

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
