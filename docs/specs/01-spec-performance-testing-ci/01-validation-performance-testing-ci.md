# 01-validation-performance-testing-ci

**Validation Date:** 2026-03-30
**Validator:** Claude Sonnet 4.6
**Branch:** `feat/performance-testing-ci` → PR #36
**Spec:** `01-spec-performance-testing-ci.md`
**Task List:** `01-tasks-performance-testing-ci.md`

---

## 1) Executive Summary

| | |
|---|---|
| **Overall** | **PASS** — all gates passed |
| **Implementation Ready** | **Yes** — all functional requirements are verified, CI check is passing on PR #36, and no blocking issues were found |
| **Requirements Verified** | 10 / 10 (100%) |
| **Proof Artifacts Working** | 6 / 6 (100%) |
| **Files Changed vs Expected** | 9 changed, 8 listed in Relevant Files + 1 justified deviation (see Issues) |

**Gates:**

| Gate | Result | Notes |
|------|--------|-------|
| A — No CRITICAL/HIGH issues | PASS | No blocking issues found |
| B — No Unknown FRs | PASS | All 10 FRs have verified evidence |
| C — Proof artifacts accessible | PASS | Both proof files exist; CI run confirmed |
| D — Changed files justified | PASS | All changes in Relevant Files or justified in commits |
| E — Repository standards | PASS | Mirrors `e2e-tests.yml` pattern; conventional commits; PR-based delivery |
| F — No credentials in artifacts | PASS | Proof artifacts contain only performance metrics and log output |

---

## 2) Coverage Matrix

### Functional Requirements

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| FR-1 | `pom.xml` defines `performance` profile with `jmeter-maven-plugin` | Verified | `pom.xml` contains `<id>performance</id>` with `jmeter-maven-plugin` 3.8.0; commit `5954b42` |
| FR-2 | Thresholds enforced: avg < 500ms, p95 < 1000ms, error rate < 1%, throughput ≥ 10 req/s | Verified | `check-thresholds.sh:15-18` — all four thresholds declared as constants; Task 1.0 proof: local run 75020 samples, all pass |
| FR-3 | `./mvnw verify -Pperformance` exits non-zero on threshold violation | Verified | Task 1.0 proof — throughput raised to 99999 req/s; exit code 1 confirmed |
| FR-4 | Workflow file `.github/workflows/performance-tests.yml` exists | Verified | File present at expected path; commit `6683ef9` |
| FR-5 | Workflow triggers on every `pull_request` event | Verified | `performance-tests.yml:4` — `on: pull_request` |
| FR-6 | Workflow starts Spring Boot (H2) and health-checks port 8080 before load test | Verified | `performance-tests.yml:24-34` — `spring-boot:run &` followed by `curl --retry 30 --retry-delay 5 --retry-connrefused http://localhost:8080/`; CI run 23765780620 step "Wait for application to be ready" passed |
| FR-7 | Workflow executes `./mvnw verify -Pperformance` and fails if exits non-zero | Verified | `performance-tests.yml:37`; CI run 23765114432 failed with `BUILD FAILURE` on threshold breach |
| FR-8 | Threshold summary printed inline to job log | Verified | Task 2.0 proof — full summary table captured from CI run 23765780620 log; avg 10ms, p95 24ms, 0.03% errors, 175 req/s |
| FR-9 | `jmeter-html-report` artifact uploaded with `if: always()` | Verified | `performance-tests.yml:39-44` — `if: always()`, artifact name `jmeter-html-report`, path `target/jmeter/reports/`; confirmed in run 23765780620 |
| FR-10 | Failed threshold check produces failed GitHub Actions check that blocks merging | Verified | Task 2.0 proof — CI run 23765114432 exited non-zero; `gh run list` shows `completed / failure`; PR check "Performance Tests" shown as failed |

### Repository Standards

| Standard | Status | Evidence & Compliance Notes |
|----------|--------|------------------------------|
| Workflow structure mirrors `e2e-tests.yml` | Verified | checkout@v4 → setup-java@v4 (Temurin 17) → build → run app → tests → upload artifact with `if: always()` — identical pattern |
| Maven profile follows existing `pom.xml` structure | Verified | `<profile><id>performance</id><build><plugins>` matches `css` and `m2e` profile structure |
| Test resources under `src/test/jmeter/` | Verified | `check-thresholds.sh` and `petclinic_test_plan.jmx` both reside under `src/test/jmeter/` |
| Conventional commits | Verified | All commits use `feat:`, `fix:`, `docs:` prefixes consistently |
| Changes delivered via PR, not direct to main | Verified | All commits on `feat/performance-testing-ci`; PR #36 open; pre-commit hook enforced |

### Proof Artifacts

| Task | Artifact | Status | Verification Result |
|------|----------|--------|---------------------|
| 1.0 | CLI: `./mvnw verify -Pperformance` exits 0, prints summary | Verified | `01-task-1-proofs.md` — 75020 samples, avg 73ms, p95 261ms, 0% errors, 1242 req/s, BUILD SUCCESS |
| 1.0 | CLI: `./mvnw verify -Pperformance` exits 1 on violation | Verified | `01-task-1-proofs.md` — throughput raised to 99999; FAIL message printed; exit code 1 |
| 2.0 | CI check "Performance Tests" passed on PR #36 | Verified | `gh run view 23765780620` → `conclusion: success`; `jmeter` job passed in 4m3s |
| 2.0 | Threshold summary visible inline in job log | Verified | Log output captured in `01-task-2-proofs.md` — full table with all four metrics and "All thresholds passed." |
| 2.0 | `jmeter-html-report` artifact available for download | Verified | "Upload JMeter HTML report" step completed successfully in run 23765780620 |
| 2.0 | CI check failed on threshold violation | Verified | Run 23765114432 — avg 3333ms and p95 5619ms exceeded thresholds; `BUILD FAILURE`; PR check shown as failed |

---

## 3) Validation Issues

| Severity | Issue | Impact | Recommendation |
|----------|-------|--------|----------------|
| MEDIUM | `petclinic_test_plan.jmx` was modified (500 threads → 50, loop-based → 90s duration), but the task list marks it "reference only, not modified" and the spec Non-Goals explicitly list "Modifying the existing test plan" as out of scope. The change was user-directed (explicitly requested during implementation) and justified in commit `7ab280b`. | Spec/task traceability gap — a future reader may be confused by the discrepancy | Update `01-tasks-performance-testing-ci.md` Relevant Files entry for `petclinic_test_plan.jmx` to reflect the actual change, and add a note to the spec Non-Goals acknowledging the deviation and its rationale |
| LOW | Task 2.0 proof artifacts are specified as "Screenshot: ..." but were captured as CLI log output (`gh run view` output and extracted job logs) rather than image screenshots. The evidence is functionally equivalent and complete, but the format differs from what the task list prescribes. | Cosmetic traceability issue — evidence is complete | No action required; note the deviation for future specs: prefer artifact type labels that match the actual capture method (e.g., "CLI output" instead of "Screenshot" for log captures) |

---

## 4) Evidence Appendix

### Git Commits Analyzed

| Commit | Message | Files Changed |
|--------|---------|---------------|
| `ef3014b` | fix: add permissions: contents: read to performance workflow | `.github/workflows/performance-tests.yml` |
| `7cbf4a6` | docs: add Task 2.0 proof artifacts and mark complete | `01-proofs/01-task-2-proofs.md`, `01-tasks-performance-testing-ci.md` |
| `9bac352` | fix: pick newest JTL CSV deterministically in check-thresholds.sh | `src/test/jmeter/check-thresholds.sh` |
| `7ab280b` | fix: reduce JMeter load for CI compatibility | `src/test/jmeter/petclinic_test_plan.jmx` |
| `6683ef9` | feat: add GitHub Actions performance tests workflow | `.github/workflows/performance-tests.yml`, `01-tasks-performance-testing-ci.md` |
| `5954b42` | feat: add Maven performance profile and threshold script | `pom.xml`, `check-thresholds.sh`, spec/task/proof docs |

### File Existence Checks

| File | Expected | Result |
|------|----------|--------|
| `.github/workflows/performance-tests.yml` | Created | ✓ Present (45 lines) |
| `src/test/jmeter/check-thresholds.sh` | Created | ✓ Present, executable (`-rwxr-xr-x`) |
| `src/test/jmeter/petclinic_test_plan.jmx` | Modified | ✓ Present, 50 threads / 90s duration confirmed |
| `pom.xml` | Modified | ✓ `performance` profile with `jmeter-maven-plugin` 3.8.0 confirmed |
| `01-proofs/01-task-1-proofs.md` | Created | ✓ Present (3.0 KB) |
| `01-proofs/01-task-2-proofs.md` | Created | ✓ Present (3.6 KB) |

### CI Run Verification

| Run ID | Conclusion | Duration | Key Output |
|--------|-----------|----------|------------|
| 23765780620 (latest) | **success** | 4m3s | avg 10ms, p95 24ms, 0.03% errors, 175 req/s — all thresholds passed |
| 23765114432 (first) | **failure** | 11m37s | avg 3333ms, p95 5619ms — FR-10 threshold enforcement verified |

### Threshold Configuration Verified

```
check-thresholds.sh:15-18
  AVG_THRESHOLD_MS=500
  P95_THRESHOLD_MS=1000
  ERROR_RATE_THRESHOLD_PCT=1
  THROUGHPUT_THRESHOLD_RPS=10
```

### JMX Configuration Verified

```
petclinic_test_plan.jmx
  ThreadGroup.num_threads = 50       (was 500)
  LoopController.continue_forever = true
  LoopController.loops = -1
  ThreadGroup.scheduler = true
  ThreadGroup.duration = 90          (seconds)
```
