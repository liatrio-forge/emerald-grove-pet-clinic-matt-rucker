# 16 Questions Round 1 - Security Scanning

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Grype Scan Target

What should Grype scan — the built container image, the CycloneDX SBOM, or both?

- [ ] (A) Scan the container image directly (`grype <image>`) — catches OS-level and app dependencies in one pass
- [ ] (B) Scan the CycloneDX SBOM only (`grype sbom:bom.json`) — faster, but misses OS-level vulnerabilities in the base image
- [x] (C) Both — scan the SBOM for app dependencies AND the image for OS-level packages
- [ ] (D) Other (describe)

## 2. Severity Threshold for Pipeline Failure

At what vulnerability severity should the pipeline fail (block deploy)?

- [ ] (A) Fail on Critical only — most permissive, only blocks showstoppers
- [x] (B) Fail on Critical + High — blocks serious vulnerabilities (matches roadmap description)
- [ ] (C) Fail on Critical + High + Medium — stricter, may cause frequent failures from transitive dependencies
- [ ] (D) Other (describe)

## 3. AWS Inspector Scope

ECR already has `scan_on_push = true` (basic scanning). Should we upgrade to AWS Inspector enhanced scanning?

- [x] (A) Keep basic ECR scanning (`scan_on_push: true`) — already enabled, no additional cost, covers common CVEs
- [ ] (B) Enable AWS Inspector enhanced scanning on ECR — continuous monitoring, richer findings, but additional cost
- [ ] (C) Enable AWS Inspector enhanced scanning AND query findings in the pipeline (poll after push, fail on critical/high)
- [ ] (D) Other (describe)

## 4. SBOM Generation

The CycloneDX Maven plugin is declared in `pom.xml` but not configured. How should we handle SBOM generation?

- [ ] (A) Configure CycloneDX in Maven to generate SBOM during `package` phase — SBOM becomes a build artifact
- [x] (B) Generate SBOM inside the Dagger pipeline only (using `syft` or similar) — keeps Maven clean
- [ ] (C) Both — Maven generates the SBOM, Dagger consumes and uploads it
- [ ] (D) Other (describe)

## 5. Scan Report Artifacts

What scan output artifacts should be produced and uploaded?

- [ ] (A) Grype JSON report only (machine-readable, can be parsed in CI)
- [ ] (B) Grype JSON + SARIF (GitHub Security tab integration)
- [x] (C) Grype JSON + SARIF + CycloneDX SBOM
- [ ] (D) Other (describe)

## 6. Pipeline Gate Placement

Where in the CI/CD flow should the scan gate sit?

- [ ] (A) After image build, before ECR push — blocks vulnerable images from ever reaching the registry
- [ ] (B) After ECR push, before ECS deploy — image in registry but deploy is blocked
- [x] (C) Both — Grype scan pre-push AND Inspector check post-push
- [ ] (D) Other (describe)

## 7. Handling Known/Accepted Vulnerabilities

How should the pipeline handle known vulnerabilities that can't be fixed immediately (e.g., in transitive dependencies)?

- [x] (A) Use a `.grype.yaml` ignore file committed to the repo — explicit allowlist of accepted CVEs with justification
- [ ] (B) No ignore mechanism — fix all critical/high before merging, no exceptions
- [ ] (C) Use `--only-fixed` flag — only fail on vulnerabilities that have a fix available
- [ ] (D) Other (describe)
