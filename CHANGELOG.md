# Changelog

All notable changes to pipeline-reconstruct-ProteomicMSMS are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- Migrate the pipeline license from GPL to BSD 3-Clause and update license documentation; shared code and third-party tools retain their respective licenses.

## [1.0.0] - 2026-11-02

### Added

- Read `sample_name,fraction_id,path` CSV input for Bruker dia-PASEF `.d` directories.
- Run diaTracer once per acquisition in the FragPipe container using a separately provided JAR.
- Publish standardized pseudo-MS/MS mzML files and SHA-512 checksums.
- Add lab-standard configuration, resources, process logging, and documentation.
- Define the FragPipe image repository and version separately.
- Add one nf-test integration case and a header-only input CSV template.
- Set the recommended Nextflow version to 25.10.5 for the shared config v2.0.0.
