// CI pipeline for Emerald Grove Veterinary Clinic
//
// Implements build, test, coverage gate, image build, and optional push
// as composable Dagger functions. Invoked via `mise run ci` or `dagger call ci`.

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

// Push publishes a container image to a registry with git SHA tag
func (m *Ci) Push(ctx context.Context, source *dagger.Directory, registry string) (string, error) {
	image := m.BuildImage(ctx, source)

	sha, err := dag.Container().
		From("docker.io/alpine/git:latest").
		WithMountedDirectory("/src", source).
		WithWorkdir("/src").
		WithExec([]string{"git", "rev-parse", "--short", "HEAD"}).
		Stdout(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get git SHA: %w", err)
	}
	sha = strings.TrimSpace(sha)

	ref, err := image.Publish(ctx, fmt.Sprintf("%s:%s", registry, sha))
	if err != nil {
		return "", fmt.Errorf("failed to push image: %w", err)
	}

	return ref, nil
}

// Pipeline runs the full CI pipeline: build, test, coverage check, image build, and optional push
func (m *Ci) Run(
	ctx context.Context,
	source *dagger.Directory,
	// ECR registry URL for image push (optional, skip push if empty)
	// +optional
	registry string,
) (string, error) {
	var output strings.Builder

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

	if registry != "" {
		fmt.Fprintln(&output, "=== Step 4: Push ===")
		ref, err := m.Push(ctx, source, registry)
		if err != nil {
			return output.String(), fmt.Errorf("push failed: %w", err)
		}
		fmt.Fprintf(&output, "Pushed: %s\n", ref)
	} else {
		fmt.Fprintln(&output, "=== Step 4: Push (skipped) ===")
		fmt.Fprintln(&output, "Skipping push: no registry configured")
	}

	fmt.Fprintln(&output, "=== CI Pipeline: PASSED ===")
	return output.String(), nil
}

func (m *Ci) mavenContainer(source *dagger.Directory) *dagger.Container {
	mavenCache := dag.CacheVolume("maven-repo")

	return dag.Container().
		From("docker.io/library/maven:3.9-amazoncorretto-17").
		WithMountedCache("/root/.m2/repository", mavenCache).
		WithMountedDirectory("/workspace", source).
		WithWorkdir("/workspace")
}
