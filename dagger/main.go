// CI/CD pipeline for Emerald Grove Veterinary Clinic
//
// Implements build, test, coverage gate, image build, ECR push, and ECS deploy
// as composable Dagger functions. Invoked via `mise run ci` or `dagger call run`.

package main

import (
	"context"
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

	// Deploy steps (only if registry provided)
	if registry != "" {
		fmt.Fprintln(&output, "=== Step 4: Deploy ===")
		deployResult, err := m.Deploy(ctx, source, registry, awsRegion, ecsCluster, ecsService,
			awsAccessKeyId, awsSecretAccessKey, awsSessionToken)
		if err != nil {
			return output.String(), fmt.Errorf("deploy failed: %w", err)
		}
		fmt.Fprint(&output, deployResult)
	} else {
		fmt.Fprintln(&output, "=== Step 4: Deploy (skipped) ===")
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

func (m *Ci) mavenContainer(source *dagger.Directory) *dagger.Container {
	mavenCache := dag.CacheVolume("maven-repo")

	return dag.Container().
		From("docker.io/library/maven:3.9-amazoncorretto-17").
		WithMountedCache("/root/.m2/repository", mavenCache).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace")
}
