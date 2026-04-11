# Task 2.0 Proof Artifacts: Dagger CI Pipeline

## dagger call run (full pipeline)

```bash
$ mise exec -- dagger -m dagger call run --source=.
✔ ci: Ci!
✔ .run(source: Address.directory: Directory!): String!

=== Step 1: Build ===
Build: PASSED
=== Step 2: Test + Coverage ===
Coverage check passed (branch coverage meets threshold)
=== Step 3: Image Build ===
Image build: PASSED
=== Step 4: Push (skipped) ===
Skipping push: no registry configured
=== CI Pipeline: PASSED ===
```

## mise run ci (identical output)

```bash
$ mise run ci
[ci] $ dagger -m dagger call run --source=.
=== Step 1: Build ===
Build: PASSED
=== Step 2: Test + Coverage ===
Coverage check passed (branch coverage meets threshold)
=== Step 3: Image Build ===
Image build: PASSED
=== Step 4: Push (skipped) ===
Skipping push: no registry configured
=== CI Pipeline: PASSED ===
```

## Failure Detection

A deliberately failing test was added to `ValidatorTests.java`:

```java
@Test
void deliberatelyFailing() {
    org.junit.jupiter.api.Assertions.fail("This test should fail");
}
```

```bash
$ mise run ci
...
[ERROR] Failed to execute goal ... MojoFailureException
! exit code: 1
[ci] ERROR task failed
```

Pipeline correctly fails and exits with non-zero status. Test was reverted after
verification.

## JaCoCo Branch Coverage Gate

Coverage gate added to `pom.xml` via JaCoCo `check` goal:

- Counter: BRANCH
- Minimum: 0.80 (80%)
- Current coverage: 84.2% (passes)

## Dagger Functions Available

```text
FUNCTIONS
  build            Build compiles the Spring Boot application
  build-image      BuildImage builds the production container image
  coverage-check   CoverageCheck runs tests and verifies the JaCoCo coverage gate
  push             Push publishes a container image to a registry with git SHA tag
  run              Pipeline runs the full CI pipeline
  test             Test runs the test suite with JaCoCo coverage
```

Each function is independently callable via `dagger -m dagger call <function>`.
