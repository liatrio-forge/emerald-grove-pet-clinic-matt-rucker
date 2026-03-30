# 01-spec-performance-testing-ci

## Introduction/Overview

This feature integrates the existing JMeter test plan into CI so that performance regressions are
caught automatically on every pull request. The JMeter test plan (`src/test/jmeter/petclinic_test_plan.jmx`)
and the pattern for running it (`./mvnw verify -Pperformance`) already exist. What is missing is
the Maven `performance` profile wiring in `pom.xml` and the GitHub Actions workflow that starts the
app, runs the load test, enforces thresholds, and publishes the HTML report. Any threshold violation
will fail the build and block the pull request from merging.

## Goals

- Catch performance regressions before they reach the `main` branch by running tests on every PR
- Wire the existing JMeter test plan into Maven so it can be invoked via `./mvnw verify -Pperformance`
- Enforce fixed thresholds (average response time, p95, error rate, throughput) and fail the build on violation
- Provide a downloadable HTML report artifact so contributors can investigate failures
- Mirror the structure and conventions of the existing `e2e-tests.yml` workflow

## User Stories

**As a developer**, I want performance tests to run automatically on every pull request so that I
know immediately if my changes degrade application performance.

**As a maintainer**, I want the CI build to fail when performance thresholds are exceeded so that
performance regressions cannot be accidentally merged into `main`.

**As a developer**, I want a downloadable HTML performance report in CI so that I can investigate
exactly which endpoints or transactions caused a failure.

**As a developer**, I want the performance test summary printed directly to the CI job log so that
I can see results at a glance without downloading an artifact.

## Demoable Units of Work

### Unit 1: GitHub Actions Performance Workflow

**Purpose:** Wire the existing JMeter test plan into CI so performance tests run automatically on
every pull request, block merging on failure, and publish an HTML report as a downloadable artifact.

**Pre-conditions (already exist):**

- JMeter test plan: `src/test/jmeter/petclinic_test_plan.jmx`
- Convention for invoking it: `./mvnw verify -Pperformance`

**Functional Requirements:**

- The `pom.xml` shall define a `performance` Maven profile that uses the `jmeter-maven-plugin` to
  execute the existing test plan during the `verify` phase, enforcing the following fixed thresholds:
  - Average response time < 500 ms
  - 95th percentile (p95) response time < 1000 ms
  - Error rate < 1%
  - Throughput ≥ 10 requests/second
- Running `./mvnw verify -Pperformance` locally against a running app shall exit non-zero if any
  threshold is violated
- The repository shall include a new workflow file `.github/workflows/performance-tests.yml`
- The workflow shall trigger on every `pull_request` event
- The workflow shall start the Spring Boot application with the default H2 profile and wait for it
  to become healthy on port 8080 before starting the load test
- The workflow shall execute `./mvnw verify -Pperformance` and fail the job if the command exits
  non-zero
- The workflow shall print a summary of threshold results (average response time, p95, error rate,
  throughput) to the job log so results are visible without downloading any artifact
- The workflow shall upload the JMeter HTML dashboard report as a GitHub Actions artifact named
  `jmeter-html-report`, even when the job fails (`if: always()`)
- A failed threshold check shall produce a failed GitHub Actions check that blocks pull request
  merging, consistent with how `e2e-tests.yml` behaves

**Proof Artifacts:**

- Screenshot: GitHub Actions check "Performance Tests" shown as failed on a PR where a threshold
  is intentionally exceeded, demonstrating the build is blocked
- Screenshot: GitHub Actions artifact `jmeter-html-report` available for download on a completed
  run, demonstrating the report is always preserved
- Screenshot: GitHub Actions check "Performance Tests" shown as passed on a clean PR,
  demonstrating the happy path works end-to-end

## Non-Goals (Out of Scope)

1. **Baseline comparison**: Comparing results against a stored historical baseline or detecting
   percentage-based regressions. Fixed thresholds are sufficient for this iteration.
2. **Scheduled / nightly runs**: The workflow triggers on pull requests only. A scheduled trigger
   can be added in a future iteration.
3. **Modifying the existing test plan**: The `.jmx` file is treated as-is. Tuning thread counts,
   endpoints, or ramp-up times is out of scope for this feature.
4. **Database-specific performance profiles**: Tests run against the default H2 in-memory database
   only. MySQL/PostgreSQL profiling is out of scope.
5. **Frontend / browser performance**: JMeter tests HTTP endpoints only. Browser-level rendering
   performance (Lighthouse, Web Vitals) is out of scope.

## Design Considerations

No specific UI/UX design requirements. The JMeter HTML dashboard is the primary human-readable
output and is generated by the `jmeter-maven-plugin` automatically.

## Repository Standards

- **Workflow structure**: Follow the pattern established in `.github/workflows/e2e-tests.yml` —
  checkout, set up JDK with Temurin distribution, run the app, run tests, upload artifacts with
  `if: always()`
- **Maven conventions**: New Maven profile must follow the existing `pom.xml` profile structure
  (see `css` and `m2e` profiles for reference)
- **Test resource location**: JMeter test plans belong under `src/test/jmeter/` to align with
  Maven's standard test resource layout
- **Commit style**: Conventional commits (`feat:`, `chore:`, etc.) as used in the project's git
  history
- **Branch protection**: Changes must be delivered via a pull request; direct commits to `main` are
  blocked by the pre-commit hook

## Technical Considerations

- **Missing Maven profile**: The `performance` profile referenced in `docs/TESTING.md` does not
  currently exist in `pom.xml` and must be added as part of this feature
- **JMeter Maven Plugin**: Use `com.lazerycode.jmeter:jmeter-maven-plugin` (current stable
  release) to run `.jmx` test plans via Maven; this avoids requiring JMeter to be installed
  separately in CI
- **Threshold enforcement**: The `jmeter-maven-plugin` supports a `<errorRateThreshold>` and can
  be combined with JMeter's built-in Summary Report assertions to enforce p95 and average response
  time; alternatively, a post-processing script can parse the JTL output and exit non-zero
- **App startup in CI**: The workflow must wait for the application to be healthy before running
  the load test. A `curl` retry loop or `wait-on` utility (already used by the Playwright config)
  is the recommended approach
- **Java version**: CI must use Java 17 (Temurin), consistent with the existing E2E workflow
- **H2 in-memory database**: No database container setup is needed; the default profile is
  sufficient for performance testing

## Security Considerations

- No API keys, credentials, or secrets are required for this feature — tests run against the local
  H2 application instance
- JMeter HTML reports may contain full request/response URLs; ensure no sensitive data appears in
  test parameters before committing the test plan
- Reports are uploaded as public GitHub Actions artifacts — do not include authentication tokens or
  PII in test parameters

## Success Metrics

1. **CI gate active**: The "Performance Tests" GitHub Actions check appears on every new pull
   request and is required to pass before merging
2. **Threshold enforcement**: A pull request that intentionally degrades response time beyond the
   threshold is blocked by a failing check
3. **Report availability**: Every workflow run (pass or fail) produces a downloadable JMeter HTML
   dashboard artifact
4. **Local reproducibility**: `./mvnw verify -Pperformance` can be run by any developer against a
   local instance and produces the same threshold evaluation as CI

## Open Questions

1. Should a minimum throughput floor (≥ 10 req/s) be enforced as a hard threshold, or tracked for
   informational purposes only? The p95 and error rate thresholds are more actionable, so throughput
   could be advisory in the first iteration.
2. The existing test plan uses 500 concurrent threads — what is the acceptable CI time budget for
   the performance job? A `timeout-minutes` cap on the workflow job may be needed to prevent runaway
   runs from blocking the PR queue.
