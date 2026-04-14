# 16-spec-security-scanning

## Introduction/Overview

Add vulnerability scanning to the Emerald Grove CI/CD pipeline so that container images with critical or high severity vulnerabilities are blocked before deployment. The pipeline will generate a CycloneDX SBOM using Syft, scan both the SBOM and the container image using Grype, and verify ECR scan findings after push — creating a defense-in-depth approach to supply chain security.

## Goals

- Detect critical and high severity vulnerabilities in application dependencies and OS packages before deployment
- Generate a CycloneDX SBOM for every build as a supply chain transparency artifact
- Fail the CI/CD pipeline when critical or high vulnerabilities are found (with an explicit allowlist for accepted exceptions)
- Produce machine-readable scan reports (Grype JSON, SARIF, SBOM) as pipeline artifacts
- Verify ECR's built-in scan findings after image push as a second gate before deploy

## User Stories

- **As a developer**, I want the CI pipeline to automatically scan my container images for vulnerabilities so that I don't accidentally deploy insecure code.
- **As a security reviewer**, I want a CycloneDX SBOM produced for every build so that I can audit the software supply chain.
- **As a platform operator**, I want the deploy step blocked when critical or high vulnerabilities are found so that production is protected by default.
- **As a developer**, I want an explicit allowlist (`.grype.yaml`) for accepted CVEs so that I can unblock the pipeline for known, risk-accepted vulnerabilities without disabling the gate entirely.

## Demoable Units of Work

### Unit 1: Grype Scan in Dagger Pipeline

**Purpose:** Add SBOM generation (Syft) and vulnerability scanning (Grype) to the Dagger CI pipeline so that every image build produces an SBOM and is scanned before push.

**Functional Requirements:**

- The Dagger pipeline shall generate a CycloneDX SBOM from the built container image using Syft
- The Dagger pipeline shall scan the CycloneDX SBOM using Grype and produce a JSON report
- The Dagger pipeline shall scan the container image directly using Grype and produce a JSON report
- The Dagger pipeline shall fail if Grype finds any vulnerability with severity Critical or High (exit code non-zero)
- The Dagger pipeline shall support a `.grype.yaml` config file in the repo root for ignoring specific CVEs
- The Dagger pipeline shall export the SBOM (CycloneDX JSON), Grype JSON report, and Grype SARIF report as artifacts
- The Dagger `Run()` function shall execute the scan step after image build and before deploy
- A new `Scan()` Dagger function shall encapsulate all scanning logic (Syft SBOM generation + Grype image scan + Grype SBOM scan) so it can be called independently

**Proof Artifacts:**

- CLI: `dagger call scan --source=.` completes and outputs scan summary (vulnerability counts by severity)
- CLI: `dagger call run --source=.` fails when a critical/high CVE is present (without `.grype.yaml` ignore)
- CLI: `dagger call run --source=.` passes when the CVE is added to `.grype.yaml` ignore list
- File: CycloneDX SBOM JSON artifact is produced in pipeline output
- File: Grype JSON and SARIF reports are produced in pipeline output

### Unit 2: ECR Scan Verification and CI Wiring

**Purpose:** After the image is pushed to ECR, verify ECR's built-in scan findings as a second gate before ECS deploy. Wire scan artifacts into the GitHub Actions workflow.

**Functional Requirements:**

- The Dagger `Deploy()` function shall, after pushing the image to ECR, wait for the ECR scan to complete and retrieve the findings
- The Dagger `Deploy()` function shall fail if ECR scan findings include any Critical or High severity vulnerabilities
- The CI IAM role shall have `ecr:DescribeImageScanFindings` permission so the pipeline can read scan results
- The GitHub Actions workflow shall upload Grype JSON, SARIF, and CycloneDX SBOM as workflow artifacts
- The GitHub Actions workflow shall upload the SARIF report to GitHub Security tab via `github/codeql-action/upload-sarif`

**Proof Artifacts:**

- CLI: `dagger call deploy --source=. ...` queries ECR scan findings after push and reports results
- CLI: Pipeline fails if ECR scan finds critical/high vulnerabilities
- GitHub: SARIF findings appear in the repository's Security > Code scanning tab
- GitHub: Workflow artifacts include `grype-report.json`, `grype-report.sarif`, and `sbom.cdx.json`

## Non-Goals (Out of Scope)

1. **AWS Inspector enhanced scanning**: We keep the existing basic ECR scan (`scan_on_push: true`). Enhanced scanning adds cost and complexity beyond what this learning exercise requires.
2. **Runtime vulnerability monitoring**: This spec covers build-time and push-time scanning only, not runtime container scanning.
3. **Automated remediation**: The pipeline will block on vulnerabilities but will not auto-upgrade dependencies or create PRs.
4. **DAST/SAST scanning**: This spec covers dependency and container image scanning only, not static application security testing or dynamic testing.
5. **Security Hub integration**: Findings remain in ECR and GitHub Security tab. No Security Hub aggregation.

## Design Considerations

No specific UI/UX design requirements. This is entirely a CI/CD pipeline change with no user-facing frontend impact.

## Repository Standards

- **Dagger pipeline**: All CI logic lives in Dagger functions (`dagger/main.go`), invoked via Mise tasks. GHA workflows are thin wrappers (Constitution Article 11).
- **Infrastructure as Code**: Any IAM permission changes go through OpenTofu modules (Constitution Article 12).
- **Conventional commits**: `feat(security): ...` for new scanning functionality, `ci(security): ...` for workflow changes.
- **Branching**: Work on `feat/security-scanning` branch, PR to `main`.

## Technical Considerations

- **Syft** generates the CycloneDX SBOM from the container image inside Dagger. This avoids configuring the CycloneDX Maven plugin and keeps SBOM generation in the pipeline where it belongs.
- **Grype** runs in Dagger containers. Two scans: one against the SBOM (`grype sbom:...`), one against the image (`grype <image>`). The image scan catches OS-level packages the SBOM misses.
- **`.grype.yaml`** in the repo root allows ignoring specific CVEs with documented justification. This file is passed into the Grype container.
- **ECR scan polling**: After `image.Publish()`, use the AWS CLI to call `aws ecr describe-image-scan-findings` in a retry loop (ECR scans take 30-60 seconds). Parse the JSON for Critical/High counts.
- **Dagger container images**: Use `anchore/grype:latest` and `anchore/syft:latest` official images.
- **SARIF upload**: The `github/codeql-action/upload-sarif@v3` action uploads Grype SARIF to GitHub's Security tab. This requires the `security-events: write` permission on the workflow.
- **Existing ECR config**: `scan_on_push = true` is already set in `infra/modules/ecr/main.tf`. No OpenTofu changes needed for ECR scanning itself.

## Security Considerations

- Grype and Syft run inside Dagger containers with no access to AWS credentials. They only see the built image and source directory.
- The `.grype.yaml` ignore file must include a justification comment for each ignored CVE so the allowlist is auditable.
- SARIF reports may contain vulnerability details — this is acceptable since the repo is private and GitHub Security tab access is already scoped to repo collaborators.
- No secrets or credentials are included in scan artifacts.

## Success Metrics

1. **Pipeline gate works**: `dagger call run --source=.` fails when a critical/high CVE exists and no ignore rule covers it
2. **SBOM produced**: Every successful pipeline run produces a CycloneDX SBOM JSON artifact
3. **Dual scan coverage**: Both SBOM-based and image-based Grype scans run on every build
4. **ECR post-push gate**: Deploy is blocked if ECR scan finds critical/high after push
5. **GitHub integration**: SARIF findings visible in repo Security > Code scanning tab
6. **Clean pipeline**: Current codebase passes the scan gate (with `.grype.yaml` ignores for any known accepted vulnerabilities)

## Open Questions

No open questions at this time.
