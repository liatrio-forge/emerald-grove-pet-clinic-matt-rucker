# Task 1.0 Proof Artifacts — Dagger Scan() Function

## dagger call scan

```text
$ mise exec -- dagger -m dagger call scan --source=.

✔ ci: Ci!
✘ .scan(source: Address.directory: Directory!): String!  1m48s ERROR
! scan failed: 2 critical, 14 high vulnerabilities found
```

The scan correctly:

1. Built the container image
2. Generated a CycloneDX SBOM with Syft
3. Scanned the SBOM with Grype (produced JSON + SARIF)
4. Scanned the container image with Grype (produced JSON)
5. Parsed vulnerability counts by severity
6. Failed the pipeline because 2 Critical + 14 High vulnerabilities were found

This proves the gate works — the pipeline blocks on Critical/High findings.

## Scan function structure

`Scan()` in `dagger/main.go`:

- Syft SBOM generation → `sbom.cdx.json`
- Grype SBOM scan → `grype-sbom.json` + `grype-report.sarif`
- Grype image scan → `grype-image.json`
- JSON parsing for severity counts
- Fail on Critical > 0 or High > 0

`ScanArtifacts()` returns a `*dagger.Directory` with all four output files.

## Run() integration

`Run()` now has 5 steps: Build → Test+Coverage → Image Build → **Security Scan** → Deploy.
The scan step runs after image build and before deploy. If scan fails, deploy is skipped.

## Note

The current codebase has real vulnerabilities (2 critical, 14 high) from dependencies and the base image. These will be addressed with `.grype.yaml` ignores in Task 3.0.
