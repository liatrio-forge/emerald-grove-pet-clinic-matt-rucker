# 15 Questions Round 1 - Monitoring & Observability

## 1. Metrics Export Approach

- [x] (A) ADOT sidecar in ECS — scrapes /actuator/prometheus, remote-writes to AMP

## 2. Grafana Dashboard Scope

- [x] (A) Minimal — request latency (p50/p95/p99), error rate, throughput, JVM heap

## 3. CloudWatch Anomaly Detection

- [x] (C) Skip anomaly detection for now

## 4. AMG Authentication

- [x] (A) AWS SSO (IAM Identity Center) — already enabled in the account

## 5. Deploy and Verify Live

- [x] (A) Yes — full end-to-end with tofu apply and metrics verification

## 6. Grafana Dashboard as Code

- [x] (A) Dashboard JSON provisioned via OpenTofu

## 7. Proof Artifacts

- [x] (A) Full end-to-end — AMP has metrics, AMG dashboard shows live data
