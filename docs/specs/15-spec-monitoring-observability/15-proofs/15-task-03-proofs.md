# Task 3.0 Proof Artifacts — Grafana Dashboard as Code

## Dashboard JSON: `infra/dashboards/overview.json`

4 panels created:

1. **Request Latency** — `histogram_quantile` at p50/p95/p99 on `http_server_requests_seconds_bucket`, unit: seconds
2. **Error Rate** — `sum(rate(...{status=~"5.."})) / sum(rate(...))`, unit: percentunit
3. **Throughput** — `sum(rate(http_server_requests_seconds_count[5m]))`, unit: reqps
4. **JVM Heap Usage** — `jvm_memory_used_bytes{area="heap"}` vs `jvm_memory_max_bytes{area="heap"}`, unit: bytes

Dashboard UID: `emerald-grove-overview`, schema version 39, auto-refresh 15s.

## Dashboard Provisioning

`terraform_data.grafana_dashboard` in `infra/modules/monitoring/main.tf` provisions the dashboard via the Grafana HTTP API using a service account token. It also creates the AMP data source in Grafana with SigV4 auth.

Note: The `grafana/grafana` Terraform provider cannot be used because provider configurations cannot reference resource attributes from the same apply. The `terraform_data` + `local-exec` approach works in a single `tofu apply`.

## tofu validate

```text
$ mise exec -- tofu -chdir=infra validate
Success! The configuration is valid.
```
