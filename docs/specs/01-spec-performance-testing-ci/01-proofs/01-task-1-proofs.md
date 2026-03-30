# Task 1.0 Proof Artifacts — Maven `performance` Profile

## Summary

Task 1.0 adds a `performance` Maven profile to `pom.xml` that:

- Runs the existing JMeter test plan via `jmeter-maven-plugin` 3.8.0
- Enforces fixed thresholds via `check-thresholds.sh` (avg < 500 ms, p95 < 1000 ms, error rate < 1%, throughput >= 10 req/s)
- Exits non-zero when any threshold is violated

---

## Proof 1 — Happy Path: `./mvnw verify -Pperformance` exits 0

Command run against a locally running Spring Boot app (H2 profile, port 8080).

```
[INFO] --- jmeter:3.8.0:results (jmeter-check-results) @ spring-petclinic ---
[INFO] Result (.csv) files scanned: 1
[INFO] Successful requests:         75020
[INFO] Failed requests:             0
[INFO] Failures:                    0.0% (1.0% accepted)

[INFO] --- exec:3.3.0:exec (check-thresholds) @ spring-petclinic ---
Parsing: target/jmeter/results/20260330-petclinic_test_plan.csv

------------------------------------------------------------
         JMeter Performance Threshold Summary
------------------------------------------------------------
  Total samples : 75020
  Test duration : 60.4 s
------------------------------------------------------------
  Avg Response Time                73 ms   (< 500 ms)
  p95 Response Time               261 ms   (< 1000 ms)
  Error Rate                      0.00%   (< 1%)
  Throughput                 1241.99 req/s   (>= 10 req/s)
------------------------------------------------------------

  All thresholds passed.

[INFO] BUILD SUCCESS
[INFO] Total time:  01:33 min
```

**Exit code: 0** — demonstrates the Maven profile and plugin configuration work end-to-end.

---

## Proof 2 — Threshold Enforcement: exit 1 on violation

Throughput threshold temporarily raised to 99999 req/s (an impossible value) and script run
directly against the real JTL results:

```
$ src/test/jmeter/check-thresholds.sh target/jmeter/results

Parsing: target/jmeter/results/20260330-petclinic_test_plan.csv

------------------------------------------------------------
         JMeter Performance Threshold Summary
------------------------------------------------------------
  Total samples : 75020
  Test duration : 60.4 s
------------------------------------------------------------
  Avg Response Time                73 ms   (< 500 ms)
  p95 Response Time               261 ms   (< 1000 ms)
  Error Rate                      0.00%   (< 1%)
  Throughput                 1241.99 req/s   (>= 99999 req/s)
------------------------------------------------------------

  FAIL: Throughput is 1241.99 req/s (threshold: >= 99999 req/s)

  One or more thresholds FAILED. See above for details.

Exit: 1
```

**Exit code: 1** — demonstrates threshold enforcement is active and the build would fail in CI.
Threshold reverted to 10 req/s immediately after this verification.

---

## Files Created / Modified

| File | Action |
|------|--------|
| `pom.xml` | Added `performance` profile with `jmeter-maven-plugin` and `exec-maven-plugin` |
| `src/test/jmeter/check-thresholds.sh` | Created — parses JTL CSV, prints summary, enforces thresholds |
