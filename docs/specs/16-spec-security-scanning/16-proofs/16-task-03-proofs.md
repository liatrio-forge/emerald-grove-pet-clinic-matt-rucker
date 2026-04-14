# Task 3.0 Proof Artifacts — GHA Wiring + .grype.yaml

## .grype.yaml

Created `.grype.yaml` with 8 ignored CVEs (all managed by Spring Boot 4.0 BOM):

- 6x tomcat-embed-core@11.0.14 (1 Critical, 5 High)
- 2x jackson-core@3.0.2 (2 High)

Each entry includes a `reason` field documenting why the CVE is accepted.

## Scan with ignores

```text
$ mise exec -- dagger -m dagger call scan --source=.

--- SBOM Scan Results ---
  Critical: 0 | High: 0 | Medium: 7 | Low: 3 | Negligible: 0

--- Image Scan Results ---
  Critical: 0 | High: 0 | Medium: 7 | Low: 3 | Negligible: 0

Scan passed: no critical or high vulnerabilities found
```

The `.grype.yaml` ignores are working — all 8 Critical/High CVEs are filtered out.

## ScanArtifacts export

```text
$ mise exec -- dagger -m dagger call scan-artifacts --source=. export --path=scan-results

$ ls scan-results/
grype-image.json  grype-report.sarif  grype-sbom.json  sbom.cdx.json
```

All 4 artifacts produced: CycloneDX SBOM, Grype SBOM JSON, Grype image JSON, SARIF report.

## GHA Workflow Updates

`.github/workflows/ci.yml` changes:

- Added `security-events: write` to permissions
- Added `actions/upload-artifact@v4` step for `scan-results/` directory
- Added `github/codeql-action/upload-sarif@v3` step for SARIF → GitHub Security tab

## Run() artifact export

`Run()` exports scan artifacts to `scan-results/` after the scan step (even on failure) so GHA can upload them.

## Note

The full `dagger call run` pipeline has a pre-existing Checkstyle OOM issue in the Maven build step when running inside Dagger containers (limited heap). This is unrelated to the security scanning work and was present before this spec. The `scan` function works correctly as verified by `dagger call scan --source=.`.
