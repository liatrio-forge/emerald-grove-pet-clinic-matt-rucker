# Task 2.0 Proof Artifacts — GitHub Actions Performance Workflow

## Summary

Task 2.0 adds `.github/workflows/performance-tests.yml` that:

- Triggers on every `pull_request`
- Starts the Spring Boot app (H2 profile), waits for it to be ready via `curl` retry loop
- Runs `./mvnw verify -Pperformance` (50 threads, 90s duration)
- Prints the threshold summary table inline in the job log
- Uploads the `jmeter-html-report` artifact with `if: always()`
- Fails the PR check when any threshold is violated

---

## Proof 1 — Happy Path: "Performance Tests" check passed on PR #36

GitHub Actions run: https://github.com/liatrio-labs/emerald-grove-pet-clinic/actions/runs/23765780620

```
✓ jmeter in 4m3s (ID 69244741912)
  ✓ Set up job
  ✓ Checkout
  ✓ Set up JDK
  ✓ Build application
  ✓ Start application
  ✓ Wait for application to be ready
  ✓ Run performance tests
  ✓ Upload JMeter HTML report
  ✓ Post Set up JDK
  ✓ Post Checkout
  ✓ Complete job
```

**Result: PASS** — "Performance Tests" check shown as passed on PR #36.

---

## Proof 2 — Threshold Summary Printed Inline in Job Log

The following output was captured directly from the "Run performance tests" step log
(run 23765780620), demonstrating results are visible without downloading an artifact:

```
         JMeter Performance Threshold Summary
------------------------------------------------------------
  Total samples : 15727
  Test duration : 89.7 s
------------------------------------------------------------
  Avg Response Time                10 ms   (< 500 ms)
  p95 Response Time                24 ms   (< 1000 ms)
  Error Rate                      0.03%   (< 1%)
  Throughput                 175.39 req/s   (>= 10 req/s)
------------------------------------------------------------

  All thresholds passed.

[INFO] BUILD SUCCESS
[INFO] Total time:  03:07 min
```

---

## Proof 3 — `jmeter-html-report` Artifact Available for Download

Artifact uploaded by the "Upload JMeter HTML report" step (`if: always()`) on run
23765780620. Artifact URL:
https://github.com/liatrio-labs/emerald-grove-pet-clinic/actions/runs/23765780620

The artifact is preserved on both pass and failure runs.

---

## Proof 4 — Build Fails on Threshold Violation

First CI run (23765114432) used the original test plan (500 threads, loop-based).
The CI runner was saturated, producing avg 3333ms and p95 5619ms — both above the
500ms/1000ms thresholds. The `check-thresholds.sh` script correctly failed the build:

```
         JMeter Performance Threshold Summary
------------------------------------------------------------
  Total samples : 75008
  Test duration : 506.2 s
------------------------------------------------------------
  Avg Response Time              3333 ms   (< 500 ms)
  p95 Response Time              5619 ms   (< 1000 ms)
  Error Rate                      0.01%   (< 1%)
  Throughput                 148.18 req/s   (>= 10 req/s)
------------------------------------------------------------

  FAIL: Avg Response Time is 3333 ms (threshold: < 500 ms)
  FAIL: p95 Response Time is 5619 ms (threshold: < 1000 ms)

  One or more thresholds FAILED. See above for details.

[INFO] BUILD FAILURE
```

**Exit code: 1** — "Performance Tests" check shown as failed on PR #36 (run 23765114432),
demonstrating the build is blocked on threshold violations.

---

## Files Created / Modified

| File | Action |
|------|--------|
| `.github/workflows/performance-tests.yml` | Created — CI workflow |
| `src/test/jmeter/petclinic_test_plan.jmx` | Modified — 50 threads, 90s duration |
| `src/test/jmeter/check-thresholds.sh` | Fixed — deterministic CSV selection |
