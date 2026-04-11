# Task 4.0 Proof Artifacts: GitHub Actions Thin Workflow

## ci.yml Line Count

```bash
$ grep -v '^\s*#' .github/workflows/ci.yml | grep -v '^\s*$' | wc -l
19
```

19 lines of YAML (under 20 line target).

## No Build Logic in Workflow

```bash
$ grep -i -E "mvnw|maven|java|npm|node|docker|podman|gradle" .github/workflows/ci.yml
(no output — no build logic found)
```

The workflow contains only: checkout → mise-action → `mise run ci` → upload artifact.

## Old Workflows Deleted

```bash
$ ls .github/workflows/
ci.yml
```

Both `e2e-tests.yml` and `performance-tests.yml` have been deleted.

## ci.yml Contents

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: jdx/mise-action@v3
      - run: mise run ci
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: target/site/jacoco/
```

All CI logic lives in Dagger (invoked via `mise run ci`). The workflow is a
thin trigger per Constitution Article 11.
