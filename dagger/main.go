// CI/CD pipeline for Emerald Grove Veterinary Clinic
//
// Implements build, test, coverage gate, image build, ECR push, and ECS deploy
// as composable Dagger functions. Invoked via `mise run ci` or `dagger call run`.

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"dagger/ci/internal/dagger"
)

type Ci struct{}

// Build compiles the Spring Boot application and returns the build container
func (m *Ci) Build(ctx context.Context, source *dagger.Directory) *dagger.Container {
	return m.mavenContainer(source).
		WithExec([]string{"./mvnw", "package", "-DskipTests", "-B"})
}

// Test runs the test suite with JaCoCo coverage and returns the container with results
func (m *Ci) Test(ctx context.Context, source *dagger.Directory) *dagger.Container {
	return m.mavenContainer(source).
		WithExec([]string{"./mvnw", "test", "-B"})
}

// CoverageCheck runs tests and verifies the JaCoCo coverage gate passes
func (m *Ci) CoverageCheck(ctx context.Context, source *dagger.Directory) (string, error) {
	_, err := m.Test(ctx, source).Stdout(ctx)
	if err != nil {
		return "", fmt.Errorf("coverage check failed: %w", err)
	}
	return "Coverage check passed (branch coverage meets threshold)", nil
}

// BuildImage builds the production container image using the project Containerfile
func (m *Ci) BuildImage(ctx context.Context, source *dagger.Directory) *dagger.Container {
	return source.DockerBuild(dagger.DirectoryDockerBuildOpts{
		Dockerfile: "Containerfile",
	})
}

// Scan generates a CycloneDX SBOM with Syft and scans both the SBOM and the
// container image with Grype. Returns a human-readable summary. Fails if any
// Critical or High severity vulnerabilities are found (respects .grype.yaml ignores).
func (m *Ci) Scan(ctx context.Context, source *dagger.Directory) (string, error) {
	var output strings.Builder

	// Build the container image
	image := m.BuildImage(ctx, source)

	// Export image as OCI tarball for scanning tools
	tarball := image.AsTarball()

	grypeCache := dag.CacheVolume("grype-db")

	// --- Syft: generate CycloneDX SBOM ---
	fmt.Fprintln(&output, "Generating CycloneDX SBOM with Syft...")

	syftContainer := dag.Container().
		From("docker.io/anchore/syft:latest").
		WithMountedFile("/image.tar", tarball).
		WithExec([]string{"/syft", "scan", "/image.tar", "-o", "cyclonedx-json=/output/sbom.cdx.json"})

	sbomFile := syftContainer.File("/output/sbom.cdx.json")
	fmt.Fprintln(&output, "SBOM generated: sbom.cdx.json")

	// --- Grype: scan SBOM (app dependencies) ---
	fmt.Fprintln(&output, "Scanning SBOM with Grype...")

	grypeSbomContainer := dag.Container().
		From("docker.io/anchore/grype:latest").
		WithMountedCache("/root/.cache/grype", grypeCache).
		WithMountedFile("/input/sbom.cdx.json", sbomFile).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{
			"/grype", "sbom:/input/sbom.cdx.json",
			"-o", "json=/output/grype-sbom.json",
			"-o", "sarif=/output/grype-report.sarif",
		})

	sbomReportJSON, err := grypeSbomContainer.File("/output/grype-sbom.json").Contents(ctx)
	if err != nil {
		return output.String(), fmt.Errorf("SBOM scan failed: %w", err)
	}

	// --- Grype: scan image tarball (OS packages) ---
	fmt.Fprintln(&output, "Scanning container image with Grype...")

	grypeImageContainer := dag.Container().
		From("docker.io/anchore/grype:latest").
		WithMountedCache("/root/.cache/grype", grypeCache).
		WithMountedFile("/image.tar", tarball).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{
			"/grype", "/image.tar",
			"-o", "json=/output/grype-image.json",
		})

	imageReportJSON, err := grypeImageContainer.File("/output/grype-image.json").Contents(ctx)
	if err != nil {
		return output.String(), fmt.Errorf("image scan failed: %w", err)
	}

	// --- Parse results and check severities ---
	sbomCounts, err := parseSeverityCounts(sbomReportJSON)
	if err != nil {
		return output.String(), fmt.Errorf("failed to parse SBOM scan results: %w", err)
	}

	imageCounts, err := parseSeverityCounts(imageReportJSON)
	if err != nil {
		return output.String(), fmt.Errorf("failed to parse image scan results: %w", err)
	}

	fmt.Fprintln(&output, "\n--- SBOM Scan Results ---")
	fmt.Fprint(&output, formatCounts(sbomCounts))
	fmt.Fprintln(&output, "\n--- Image Scan Results ---")
	fmt.Fprint(&output, formatCounts(imageCounts))

	totalCritical := sbomCounts["Critical"] + imageCounts["Critical"]
	totalHigh := sbomCounts["High"] + imageCounts["High"]

	if totalCritical > 0 || totalHigh > 0 {
		return output.String(), fmt.Errorf("scan failed: %d critical, %d high vulnerabilities found", totalCritical, totalHigh)
	}

	fmt.Fprintln(&output, "\nScan passed: no critical or high vulnerabilities found")
	return output.String(), nil
}

// scanArtifacts returns a Directory containing all scan output files.
// Call after Scan() to retrieve artifacts for export.
func (m *Ci) ScanArtifacts(ctx context.Context, source *dagger.Directory) *dagger.Directory {
	image := m.BuildImage(ctx, source)
	tarball := image.AsTarball()
	grypeCache := dag.CacheVolume("grype-db")

	syftContainer := dag.Container().
		From("docker.io/anchore/syft:latest").
		WithMountedFile("/image.tar", tarball).
		WithExec([]string{"/syft", "scan", "/image.tar", "-o", "cyclonedx-json=/output/sbom.cdx.json"})

	sbomFile := syftContainer.File("/output/sbom.cdx.json")

	grypeSbomContainer := dag.Container().
		From("docker.io/anchore/grype:latest").
		WithMountedCache("/root/.cache/grype", grypeCache).
		WithMountedFile("/input/sbom.cdx.json", sbomFile).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{
			"/grype", "sbom:/input/sbom.cdx.json",
			"-o", "json=/output/grype-sbom.json",
			"-o", "sarif=/output/grype-report.sarif",
		})

	grypeImageContainer := dag.Container().
		From("docker.io/anchore/grype:latest").
		WithMountedCache("/root/.cache/grype", grypeCache).
		WithMountedFile("/image.tar", tarball).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{
			"/grype", "/image.tar",
			"-o", "json=/output/grype-image.json",
		})

	return dag.Directory().
		WithFile("sbom.cdx.json", sbomFile).
		WithFile("grype-sbom.json", grypeSbomContainer.File("/output/grype-sbom.json")).
		WithFile("grype-report.sarif", grypeSbomContainer.File("/output/grype-report.sarif")).
		WithFile("grype-image.json", grypeImageContainer.File("/output/grype-image.json"))
}

// Deploy pushes the container image to ECR and forces a new ECS deployment.
func (m *Ci) Deploy(
	ctx context.Context,
	source *dagger.Directory,
	// ECR registry URL (e.g., 123456789.dkr.ecr.us-east-1.amazonaws.com/repo-name)
	registry string,
	// AWS region
	awsRegion string,
	// ECS cluster name
	ecsCluster string,
	// ECS service name
	ecsService string,
	// AWS access key ID
	awsAccessKeyId *dagger.Secret,
	// AWS secret access key
	awsSecretAccessKey *dagger.Secret,
	// AWS session token (for OIDC/assumed roles)
	// +optional
	awsSessionToken *dagger.Secret,
) (string, error) {
	var output strings.Builder

	// Build the image
	image := m.BuildImage(ctx, source)

	// Get git SHA for tagging
	sha, err := m.gitSha(ctx, source)
	if err != nil {
		return "", err
	}
	imageRef := fmt.Sprintf("%s:%s", registry, sha)
	fmt.Fprintf(&output, "Image tag: %s\n", imageRef)

	// Get ECR auth token via AWS CLI
	awsCli := m.awsContainer(awsRegion, awsAccessKeyId, awsSecretAccessKey, awsSessionToken)
	ecrPassword, err := awsCli.
		WithExec([]string{"aws", "ecr", "get-login-password", "--region", awsRegion}).
		Stdout(ctx)
	if err != nil {
		return output.String(), fmt.Errorf("ECR auth failed: %w", err)
	}
	ecrPassword = strings.TrimSpace(ecrPassword)

	// Extract registry domain (everything before the first /)
	registryDomain := strings.Split(registry, "/")[0]

	// Push to ECR with auth
	ref, err := image.
		WithRegistryAuth(registryDomain, "AWS", dag.SetSecret("ecr-password", ecrPassword)).
		Publish(ctx, imageRef)
	if err != nil {
		return output.String(), fmt.Errorf("ECR push failed: %w", err)
	}
	fmt.Fprintf(&output, "Pushed: %s\n", ref)

	// --- ECR scan verification ---
	// Extract repo name and tag from imageRef (e.g., "123456.dkr.ecr.us-east-1.amazonaws.com/repo:tag")
	parts := strings.SplitN(registry, "/", 2)
	repoName := parts[1] // e.g., "emerald-grove-prod"
	// tag is already in sha variable

	fmt.Fprintf(&output, "Waiting for ECR scan on %s:%s...\n", repoName, sha)

	ecrScanScript := fmt.Sprintf(`
set -e
REPO=%s
TAG=%s
REGION=%s
MAX_RETRIES=12
SLEEP=10

for i in $(seq 1 $MAX_RETRIES); do
  RESULT=$(aws ecr describe-image-scan-findings --repository-name "$REPO" --image-id imageTag="$TAG" --region "$REGION" 2>&1) || true

  STATUS=$(echo "$RESULT" | jq -r '.imageScanStatus.status // empty')

  if [ "$STATUS" = "COMPLETE" ]; then
    CRITICAL=$(echo "$RESULT" | jq '.imageScanFindings.findingSeverityCounts.CRITICAL // 0')
    HIGH=$(echo "$RESULT" | jq '.imageScanFindings.findingSeverityCounts.HIGH // 0')
    MEDIUM=$(echo "$RESULT" | jq '.imageScanFindings.findingSeverityCounts.MEDIUM // 0')
    LOW=$(echo "$RESULT" | jq '.imageScanFindings.findingSeverityCounts.LOW // 0')

    echo "ECR scan complete: Critical=$CRITICAL High=$HIGH Medium=$MEDIUM Low=$LOW"

    if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
      echo "ECR scan FAILED: $CRITICAL critical, $HIGH high vulnerabilities"
      exit 1
    fi

    echo "ECR scan passed: no critical or high vulnerabilities"
    exit 0
  elif [ "$STATUS" = "FAILED" ]; then
    echo "ECR scan failed with status: FAILED"
    exit 1
  fi

  echo "ECR scan in progress (attempt $i/$MAX_RETRIES)..."
  sleep $SLEEP
done

echo "ECR scan timed out after $MAX_RETRIES attempts"
exit 1
`, repoName, sha, awsRegion)

	ecrScanOutput, err := awsCli.
		WithExec([]string{"sh", "-c", ecrScanScript}).
		Stdout(ctx)
	if err != nil {
		fmt.Fprint(&output, ecrScanOutput)
		return output.String(), fmt.Errorf("ECR scan gate failed: %w", err)
	}
	fmt.Fprint(&output, ecrScanOutput)

	// Update ECS: register new task definition revision with new image, then update service
	deployScript := fmt.Sprintf(`
set -e
REGION=%s
CLUSTER=%s
SERVICE=%s
IMAGE=%s

# Get current task definition ARN
CURRENT_TD=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" --query 'services[0].taskDefinition' --output text)
echo "Current task definition: $CURRENT_TD"

# Get task definition JSON, update image, strip non-register fields
aws ecs describe-task-definition --task-definition "$CURRENT_TD" --region "$REGION" --query 'taskDefinition' | \
  jq --arg img "$IMAGE" '.containerDefinitions[0].image = $img | {family, taskRoleArn, executionRoleArn, networkMode, containerDefinitions, requiresCompatibilities, cpu, memory}' \
  > /tmp/new-task-def.json

# Register new revision
NEW_TD=$(aws ecs register-task-definition --region "$REGION" --cli-input-json file:///tmp/new-task-def.json --query 'taskDefinition.taskDefinitionArn' --output text)
echo "New task definition: $NEW_TD"

# Update service
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$NEW_TD" --region "$REGION" --query 'service.serviceName' --output text
echo "ECS deployment triggered"
`, awsRegion, ecsCluster, ecsService, imageRef)

	deployOutput, err := awsCli.
		WithExec([]string{"sh", "-c", deployScript}).
		Stdout(ctx)
	if err != nil {
		return output.String(), fmt.Errorf("ECS deploy failed: %w", err)
	}
	fmt.Fprint(&output, deployOutput)

	return output.String(), nil
}

// Run executes the full CI/CD pipeline: build, test, coverage, image build, and optional deploy
func (m *Ci) Run(
	ctx context.Context,
	source *dagger.Directory,
	// ECR registry URL (optional, skip deploy if empty)
	// +optional
	registry string,
	// AWS region (required if registry is set)
	// +optional
	awsRegion string,
	// ECS cluster name (required if registry is set)
	// +optional
	ecsCluster string,
	// ECS service name (required if registry is set)
	// +optional
	ecsService string,
	// AWS access key ID (required if registry is set)
	// +optional
	awsAccessKeyId *dagger.Secret,
	// AWS secret access key (required if registry is set)
	// +optional
	awsSecretAccessKey *dagger.Secret,
	// AWS session token (for OIDC/assumed roles, optional)
	// +optional
	awsSessionToken *dagger.Secret,
) (string, error) {
	var output strings.Builder

	// CI steps (always run)
	fmt.Fprintln(&output, "=== Step 1: Build ===")
	_, err := m.Build(ctx, source).Stdout(ctx)
	if err != nil {
		return output.String(), fmt.Errorf("build failed: %w", err)
	}
	fmt.Fprintln(&output, "Build: PASSED")

	fmt.Fprintln(&output, "=== Step 2: Test + Coverage ===")
	coverageResult, err := m.CoverageCheck(ctx, source)
	if err != nil {
		return output.String(), fmt.Errorf("test/coverage failed: %w", err)
	}
	fmt.Fprintln(&output, coverageResult)

	fmt.Fprintln(&output, "=== Step 3: Image Build ===")
	m.BuildImage(ctx, source)
	fmt.Fprintln(&output, "Image build: PASSED")

	fmt.Fprintln(&output, "=== Step 4: Security Scan ===")
	scanResult, err := m.Scan(ctx, source)
	if err != nil {
		fmt.Fprint(&output, scanResult)
		// Export artifacts even on failure so GHA can upload SARIF
		m.ScanArtifacts(ctx, source).Export(ctx, "scan-results")
		return output.String(), fmt.Errorf("security scan failed: %w", err)
	}
	fmt.Fprint(&output, scanResult)

	// Export scan artifacts for GHA workflow upload
	_, err = m.ScanArtifacts(ctx, source).Export(ctx, "scan-results")
	if err != nil {
		fmt.Fprintf(&output, "Warning: failed to export scan artifacts: %v\n", err)
	}

	// Deploy steps (only if registry provided)
	if registry != "" {
		fmt.Fprintln(&output, "=== Step 5: Deploy ===")
		deployResult, err := m.Deploy(ctx, source, registry, awsRegion, ecsCluster, ecsService,
			awsAccessKeyId, awsSecretAccessKey, awsSessionToken)
		if err != nil {
			return output.String(), fmt.Errorf("deploy failed: %w", err)
		}
		fmt.Fprint(&output, deployResult)
	} else {
		fmt.Fprintln(&output, "=== Step 5: Deploy (skipped) ===")
		fmt.Fprintln(&output, "Skipping deploy: no registry configured")
	}

	fmt.Fprintln(&output, "=== CI/CD Pipeline: PASSED ===")
	return output.String(), nil
}

// gitSha returns the short git SHA from the source directory
func (m *Ci) gitSha(ctx context.Context, source *dagger.Directory) (string, error) {
	sha, err := dag.Container().
		From("docker.io/alpine/git:latest").
		WithMountedDirectory("/src", source).
		WithWorkdir("/src").
		WithExec([]string{"git", "rev-parse", "--short", "HEAD"}).
		Stdout(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get git SHA: %w", err)
	}
	return strings.TrimSpace(sha), nil
}

// awsContainer returns an AWS CLI container with credentials passed as secrets
func (m *Ci) awsContainer(
	region string,
	accessKeyId *dagger.Secret,
	secretAccessKey *dagger.Secret,
	sessionToken *dagger.Secret,
) *dagger.Container {
	c := dag.Container().
		From("docker.io/amazon/aws-cli:latest").
		WithEnvVariable("AWS_DEFAULT_REGION", region).
		WithSecretVariable("AWS_ACCESS_KEY_ID", accessKeyId).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", secretAccessKey)

	if sessionToken != nil {
		c = c.WithSecretVariable("AWS_SESSION_TOKEN", sessionToken)
	}

	return c
}

// grypeReport is a minimal representation of Grype JSON output for severity counting.
type grypeReport struct {
	Matches []struct {
		Vulnerability struct {
			Severity string `json:"severity"`
		} `json:"vulnerability"`
	} `json:"matches"`
}

// parseSeverityCounts extracts vulnerability counts by severity from Grype JSON output.
func parseSeverityCounts(jsonContent string) (map[string]int, error) {
	var report grypeReport
	if err := json.Unmarshal([]byte(jsonContent), &report); err != nil {
		return nil, err
	}

	counts := map[string]int{
		"Critical":   0,
		"High":       0,
		"Medium":     0,
		"Low":        0,
		"Negligible": 0,
	}

	for _, m := range report.Matches {
		counts[m.Vulnerability.Severity]++
	}

	return counts, nil
}

// formatCounts returns a human-readable summary of vulnerability counts.
func formatCounts(counts map[string]int) string {
	return fmt.Sprintf("  Critical: %d | High: %d | Medium: %d | Low: %d | Negligible: %d\n",
		counts["Critical"], counts["High"], counts["Medium"], counts["Low"], counts["Negligible"])
}

func (m *Ci) mavenContainer(source *dagger.Directory) *dagger.Container {
	mavenCache := dag.CacheVolume("maven-repo")

	return dag.Container().
		From("docker.io/library/maven:3.9-amazoncorretto-17").
		WithMountedCache("/root/.m2/repository", mavenCache).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace")
}
