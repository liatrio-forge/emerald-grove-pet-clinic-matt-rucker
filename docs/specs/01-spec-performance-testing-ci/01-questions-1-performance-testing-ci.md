# 01 Questions Round 1 - Performance Testing CI

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Trigger: When should the performance tests run in CI?

When should the GitHub Actions performance workflow be triggered?

- [ X ] (A) On every pull request (same as E2E tests)
- [ ] (B) On push to main only
- [ ] (C) On a schedule (e.g., nightly)
- [ ] (D) On every pull request AND on a schedule
- [ ] (E) Other (describe)

## 2. Failure Behavior: What should happen when a performance threshold is exceeded?

- [ X ] (A) Fail the CI build (block merging)
- [ ] (B) Warn only — post results as a comment or annotation but do not block the build
- [ ] (C) Fail only on push to main; warn on pull requests
- [ ] (D) Other (describe)

## 3. Thresholds: What performance thresholds matter to you?

Which metrics should be measured and enforced? Select all that apply.

- [ X ] (A) Average response time (e.g., must be under 500ms)
- [ X ] (B) 95th percentile response time (p95)
- [ X ] (C) Error rate (e.g., must be below 1%)
- [ X ] (D) Throughput (requests per second)
- [ ] (E) Other (describe)

## 4. Endpoints: Which pages or endpoints should be load tested?

- [ ] (A) Home page only (`/`)
- [ X ] (B) A small representative set (e.g., home, owner list, vet list)
- [ ] (C) All major user-facing pages (owners, pets, vets, visits)
- [ ] (D) I want to define the exact list (add details below)
- [ ] (E) Other (describe)

## 5. Load Profile: How much simulated load should the tests apply?

- [ ] (A) Light — a few concurrent users (e.g., 5–10) for a short duration (30s)
- [ X ] (B) Moderate — 20–50 concurrent users for 1–2 minutes
- [ ] (C) Heavy — 100+ concurrent users
- [ ] (D) I want to configure this myself (add details below)
- [ ] (E) Other (describe)

## 6. Baseline / Regression Detection: How should regressions be detected?

- [ X ] (A) Fixed thresholds only (e.g., p95 < 500ms, error rate < 1%) — simple and predictable
- [ ] (B) Compare against a stored baseline from a previous run and fail if degraded by X%
- [ ] (C) Both — fixed thresholds as a hard floor, plus trend comparison
- [ ] (D) Other (describe)

## 7. Reports: What performance test artifacts should CI preserve?

- [ X ] (A) JMeter HTML dashboard report (uploaded as a workflow artifact)
- [ ] (B) JMeter JTL/CSV raw results only
- [ ] (C) Both HTML dashboard and raw results
- [ ] (D) No artifacts needed — pass/fail is enough
- [ ] (E) Other (describe)
