# Task 1.0 Proof Artifacts: Spring Boot Micrometer Prometheus Metrics

## /actuator/prometheus endpoint

```bash
$ curl http://localhost:8080/actuator/prometheus | grep -E "^(http_server|jvm_memory_used|hikaricp)" | head -10
hikaricp_connections_active{pool="HikariPool-1"} 0.0
hikaricp_connections{pool="HikariPool-1"} 10.0
http_server_requests_active_seconds_count{...} 1
jvm_memory_used_bytes{area="heap",id="G1 Eden Space"} 7.13E7
```

All three required metric families present:

- `http_server_requests_*` — HTTP request metrics
- `jvm_memory_used_bytes` — JVM heap memory
- `hikaricp_connections_active` — DB connection pool

## Tests

```text
Tests run: 124, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

No regressions from adding micrometer-registry-prometheus dependency.
