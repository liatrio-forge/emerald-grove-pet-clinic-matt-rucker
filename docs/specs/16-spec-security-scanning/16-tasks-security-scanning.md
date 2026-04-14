# 16-tasks-security-scanning

Task list for [16-spec-security-scanning](16-spec-security-scanning.md).

## Relevant Files

- `dagger/main.go` - **Modify.** Add `Scan()` function (Syft SBOM + Grype scans), update `Run()` to call Scan between image build and deploy, update `Deploy()` to poll ECR scan findings after push.
- `.github/workflows/ci.yml` - **Modify.** Add scan artifact export step, SARIF upload to GitHub Security tab, `security-events: write` permission.
- `.grype.yaml` - **New file.** Grype configuration for ignoring accepted CVEs with justification comments.
- `infra/modules/identity/main.tf` - **Modify.** Add `ecr:DescribeImageScanFindings` to CI role permissions.
- `docs/specs/16-spec-security-scanning/16-proofs/` - **New directory.** Proof artifact outputs.

### Notes

- Use `mise exec -- dagger call ...` for all Dagger invocations in Claude Code's shell.
- Syft image: `docker.io/anchore/syft:latest`. Grype image: `docker.io/anchore/grype:latest`.
- Grype fails with exit code 1 when vulnerabilities at or above the configured severity are found (`--fail-on high`).
- ECR basic scan results are available via `aws ecr describe-image-scan-findings`. The scan status field transitions from `IN_PROGRESS` to `COMPLETE` or `FAILED`.
- Follow conventional commits: `feat(security): ...` for Dagger changes, `ci(security): ...` for workflow changes.
- All scanning resources must work locally (`dagger call scan`) and in CI (GHA workflow).

## Tasks

### [x] 1.0 Dagger Scan() Function — Syft SBOM + Grype Vulnerability Scan

Add a new `Scan()` function to `dagger/main.go` that generates a CycloneDX SBOM with Syft, then scans both the SBOM and the container image with Grype. The function fails on Critical/High severity findings and exports SBOM, Grype JSON, and SARIF as artifacts. Wire `Scan()` into `Run()` between image build and deploy.

#### 1.0 Proof Artifact(s)

- CLI: `dagger call scan --source=.` completes and outputs vulnerability counts by severity
- CLI: `dagger call run --source=.` executes scan step after image build (visible in step output)
- File: CycloneDX SBOM JSON, Grype JSON report, and Grype SARIF report are exported from the pipeline

#### 1.0 Tasks

- [ ] 1.1 Add a `Scan()` function to `dagger/main.go` that accepts `source *dagger.Directory` and returns `(*dagger.Directory, string, error)` — the directory contains scan artifacts, the string is a human-readable summary. Inside `Scan()`:
  - Build the container image using `m.BuildImage(ctx, source)`.
  - Export the image as a tarball to a scratch container (using `image.AsTarball()` and mounting it) so Syft and Grype can scan it.
  - Run Syft against the image tarball to produce a CycloneDX JSON SBOM: container from `anchore/syft:latest`, mount the tarball, exec `syft packages /image.tar -o cyclonedx-json=/output/sbom.cdx.json`.
  - Run Grype against the CycloneDX SBOM: container from `anchore/grype:latest`, mount the SBOM file and `.grype.yaml` (if it exists in source), exec `grype sbom:/input/sbom.cdx.json --fail-on high -o json=/output/grype-sbom.json -o sarif=/output/grype-report.sarif`.
  - Run Grype against the image tarball directly: container from `anchore/grype:latest`, mount the tarball and `.grype.yaml`, exec `grype /image.tar --fail-on high -o json=/output/grype-image.json`.
  - Collect all output files (`sbom.cdx.json`, `grype-sbom.json`, `grype-image.json`, `grype-report.sarif`) into a single output directory.
  - Build a summary string with vulnerability counts from the Grype JSON output.
  - Return the output directory and summary.
- [ ] 1.2 Update `Run()` in `dagger/main.go` to add a scan step between "Step 3: Image Build" and "Step 4: Deploy". Call `m.Scan(ctx, source)` and print the summary. If scan fails (returns error), the pipeline fails.
- [ ] 1.3 Test locally: run `mise exec -- dagger call scan --source=.` and verify it completes. Capture the output showing vulnerability counts by severity.
- [ ] 1.4 Test locally: run `mise exec -- dagger call run --source=.` and verify the scan step appears between image build and deploy in the output.
- [ ] 1.5 Save proof artifact output to `docs/specs/16-spec-security-scanning/16-proofs/16-task-01-proofs.md`.

### [x] 2.0 ECR Scan Verification in Deploy() + IAM Permissions

After pushing the image to ECR in `Deploy()`, poll `aws ecr describe-image-scan-findings` until the scan completes, then fail if Critical or High severity findings exist. Add `ecr:DescribeImageScanFindings` to the CI IAM role in OpenTofu.

#### 2.0 Proof Artifact(s)

- CLI: `dagger call deploy --source=. ...` outputs ECR scan findings summary after push
- CLI: Deploy fails if ECR scan finds critical/high vulnerabilities
- Diff: `infra/modules/identity/main.tf` shows `ecr:DescribeImageScanFindings` added to CI role
- CLI: `tofu validate` passes

#### 2.0 Tasks

- [ ] 2.1 Add an ECR scan check to `Deploy()` in `dagger/main.go` after the `image.Publish()` call and before the ECS update script. Using the existing `awsCli` container:
  - Extract the repository name and image tag from the `imageRef` (split on `/` and `:`).
  - Run a shell script that polls `aws ecr describe-image-scan-findings --repository-name <repo> --image-id imageTag=<tag> --region <region>` in a loop (sleep 10s between retries, max 12 retries = 2 minutes). Check the `imageScanStatus.status` field — retry while `IN_PROGRESS`, proceed on `COMPLETE`, fail on `FAILED` or timeout.
  - Once `COMPLETE`, parse the `findingSeverityCounts` from the JSON response. If `CRITICAL` or `HIGH` counts are > 0, print the counts and return an error to block the ECS deploy.
  - If no Critical/High findings, print a success summary and continue to the ECS update.
- [ ] 2.2 Update `infra/modules/identity/main.tf`: add `ecr:DescribeImageScanFindings` to the CI role's `ECRPush` statement (or create a new statement `ECRScan` scoped to the ECR repository ARN).
- [ ] 2.3 Validate: run `mise exec -- tofu -chdir=infra validate` (with `-backend=false` init if needed) and confirm it passes.
- [ ] 2.4 Save proof artifact output to `docs/specs/16-spec-security-scanning/16-proofs/16-task-02-proofs.md`.

### [x] 3.0 GitHub Actions Wiring + .grype.yaml Ignore File

Update the GHA CI workflow to upload scan artifacts (SBOM, Grype JSON, SARIF) and publish SARIF to GitHub Security tab. Create a `.grype.yaml` config file for CVE allowlisting. Verify the full pipeline passes with the current codebase.

#### 3.0 Proof Artifact(s)

- Diff: `.github/workflows/ci.yml` shows artifact upload and SARIF upload steps, `security-events: write` permission
- File: `.grype.yaml` exists with documented format for ignoring CVEs
- CLI: `dagger call run --source=.` passes end-to-end with the current codebase (using `.grype.yaml` ignores if needed)
- CLI: Full pipeline proof saved to `docs/specs/16-spec-security-scanning/16-proofs/`

#### 3.0 Tasks

- [ ] 3.1 Create `.grype.yaml` in the repo root with the Grype configuration format. Include a commented example showing how to ignore a specific CVE with justification:

  ```yaml
  ignore:
    # Example: accepted risk — no fix available for transitive dependency
    # - vulnerability: CVE-YYYY-XXXXX
    #   reason: "No fix available; mitigated by network policy"
  ```

  If the current codebase has Critical/High findings that cannot be fixed immediately, add the specific CVEs to the ignore list with justification.
- [ ] 3.2 Update the `Scan()` function (or `Run()`) in `dagger/main.go` to export the scan artifacts directory to the host. The Dagger `Directory.Export()` method writes files to a local path. Export to a well-known path (e.g., `scan-results/`) that GHA can pick up.
- [ ] 3.3 Update `.github/workflows/ci.yml`:
  - Add `security-events: write` to the `permissions` block.
  - After `mise run ci`, add an artifact upload step using `actions/upload-artifact@v4` for the scan results directory (`scan-results/`) containing `sbom.cdx.json`, `grype-sbom.json`, `grype-image.json`, and `grype-report.sarif`.
  - Add a SARIF upload step using `github/codeql-action/upload-sarif@v3` pointing to `scan-results/grype-report.sarif`. This step should run `if: always()` so SARIF is uploaded even if the scan fails.
- [ ] 3.4 Run the full pipeline locally: `mise exec -- dagger call run --source=.`. Verify it passes end-to-end (build → test → coverage → image build → scan → done). If scan fails on real CVEs, add them to `.grype.yaml` with justification and re-run.
- [ ] 3.5 Save proof artifact output to `docs/specs/16-spec-security-scanning/16-proofs/16-task-03-proofs.md`.
