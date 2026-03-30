# 01-tasks-performance-testing-ci

## Relevant Files

- `pom.xml` - Add the `performance` Maven profile with `jmeter-maven-plugin` configuration and
  the exec step that runs the threshold script after JMeter finishes.
- `src/test/jmeter/petclinic_test_plan.jmx` - Existing test plan (reference only, not modified).
- `src/test/jmeter/check-thresholds.sh` - New shell script that parses the JTL CSV produced by
  JMeter, prints a summary table to stdout, and exits non-zero if any threshold is violated.
- `.github/workflows/performance-tests.yml` - New GitHub Actions workflow that starts the app,
  runs the load test, and uploads the HTML report artifact.

### Notes

- Follow the profile structure already established in `pom.xml` (see `css` and `m2e` profiles).
- Follow the workflow structure already established in `.github/workflows/e2e-tests.yml` (checkout
  → setup-java Temurin 17 → run tests → upload artifacts with `if: always()`).
- The JMeter test plan has no built-in response time or throughput assertions. All threshold
  enforcement is delegated to `check-thresholds.sh`, which parses the JTL CSV output.
- Changes must be delivered via a pull request — direct commits to `main` are blocked.

## Tasks

### [x] 1.0 Add Maven `performance` Profile to `pom.xml`

Wire the existing JMeter test plan into Maven so the load test can be invoked locally and in CI
via `./mvnw verify -Pperformance`, with thresholds enforced by a post-processing script.

#### 1.0 Proof Artifact(s)

- CLI: `./mvnw verify -Pperformance` run against a locally running app exits 0 and prints a
  threshold summary table, demonstrating the Maven profile and plugin configuration work
  end-to-end
- CLI: `./mvnw verify -Pperformance` exits non-zero when a threshold is intentionally violated
  (e.g., by temporarily lowering the error-rate threshold in `check-thresholds.sh` to `0`),
  demonstrating enforcement is active

#### 1.0 Tasks

- [x] 1.1 Add `jmeter-maven-plugin` (`com.lazerycode.jmeter`) to `pom.xml` inside a new
  `<profile>` with `<id>performance</id>`. Configure it to:
  - reference `src/test/jmeter/petclinic_test_plan.jmx` as the test plan
  - write JTL results in CSV format to `target/jmeter/results/`
  - generate the HTML dashboard report to `target/jmeter/reports/`
  - bind execution to the `verify` phase
- [x] 1.2 Write `src/test/jmeter/check-thresholds.sh`. The script must:
  - accept the path to the JTL CSV file as its first argument
  - parse the CSV to compute: average response time, p95 response time, error rate, and
    throughput (requests/second)
  - print a clearly formatted summary table to stdout showing each metric and its threshold
  - exit 1 if any of the following are violated:
    - average response time ≥ 500 ms
    - p95 response time ≥ 1000 ms
    - error rate ≥ 1%
    - throughput < 10 req/s
  - exit 0 if all thresholds pass
- [x] 1.3 Add an `exec-maven-plugin` execution to the `performance` profile that runs
  `check-thresholds.sh` after JMeter finishes (bind to `post-integration-test` phase), passing
  the path to the generated JTL CSV file as the argument.
- [x] 1.4 Start the application locally (`./mvnw spring-boot:run`) and run
  `./mvnw verify -Pperformance` to confirm the profile executes JMeter, the summary table
  is printed to the console, and the command exits 0 on a clean run.
- [x] 1.5 Temporarily change a threshold in `check-thresholds.sh` to an impossible value (e.g.,
  error rate threshold to `0%`) and rerun `./mvnw verify -Pperformance` to confirm the command
  exits non-zero and the summary clearly shows which threshold failed. Revert the change
  afterward.

---

### [x] 2.0 Create GitHub Actions Performance Workflow

Add `.github/workflows/performance-tests.yml` that starts the application, runs the load test,
prints the threshold summary to the job log, uploads the HTML report as an artifact, and fails
the PR check on any threshold violation.

#### 2.0 Proof Artifact(s)

- Screenshot: GitHub Actions check "Performance Tests" shown as passed on a clean PR,
  demonstrating the happy path works end-to-end
- Screenshot: Job log output showing the printed threshold summary table (avg, p95, error rate,
  throughput) inline in the workflow run, demonstrating results are visible without downloading
  an artifact
- Screenshot: GitHub Actions artifact `jmeter-html-report` available for download on a completed
  run, demonstrating the report is always preserved (even on failure)
- Screenshot: GitHub Actions check "Performance Tests" shown as failed on a PR where a threshold
  is intentionally exceeded, demonstrating the build is blocked

#### 2.0 Tasks

- [x] 2.1 Create `.github/workflows/performance-tests.yml` with:
  - `name: Performance Tests`
  - `on: pull_request`
  - a single job named `jmeter` running on `ubuntu-latest` with `timeout-minutes: 15`
- [x] 2.2 Add the following steps to the job, following the pattern in `e2e-tests.yml`:
  - `actions/checkout@v4`
  - `actions/setup-java@v4` with `distribution: temurin` and `java-version: '17'`
- [x] 2.3 Add a step that builds the application without running tests:
  `./mvnw package -DskipTests` (produces the runnable JAR before starting the app).
- [x] 2.4 Add a step that starts the Spring Boot application in the background using the default
  H2 profile: `./mvnw spring-boot:run &`
- [x] 2.5 Add a health-check step that polls `http://localhost:8080/` using a `curl` retry loop
  and waits until the app responds with HTTP 200 before continuing. Use `--retry 30`,
  `--retry-delay 5`, and `--retry-connrefused` so the step fails fast if the app never starts
  rather than hanging.
- [x] 2.6 Add a step that runs `./mvnw verify -Pperformance`. Because `check-thresholds.sh`
  prints the summary table to stdout and exits non-zero on violation, the job log will show the
  summary inline and the workflow step will fail automatically on a threshold breach.
- [x] 2.7 Add an artifact upload step using `actions/upload-artifact@v4` with:
  - `name: jmeter-html-report`
  - `path: target/jmeter/reports/`
  - `if: always()` so the report is preserved on both pass and failure
- [x] 2.8 Open a pull request with these changes and confirm the "Performance Tests" check
  appears in the PR checks list and passes. Capture the screenshots required by the proof
  artifacts above.
