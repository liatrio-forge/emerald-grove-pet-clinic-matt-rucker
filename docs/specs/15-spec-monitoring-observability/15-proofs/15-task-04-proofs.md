# Task 4.0 Proof Artifacts — Deploy, Verify End-to-End, and Teardown

## 4.1 Bootstrap State Backend

```text
$ mise exec -- tofu -chdir=infra/bootstrap apply -auto-approve \
    -var='state_bucket_name=emerald-grove-tfstate' \
    -var='lock_table_name=emerald-grove-tflock'

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:
lock_table_name = "emerald-grove-tflock"
region = "us-east-1"
state_bucket_name = "emerald-grove-tfstate"
```

## 4.2 Apply Infrastructure

```text
$ mise exec -- tofu -chdir=infra apply -var-file=environments/prod.tfvars -auto-approve

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "emerald-grove-prod-alb-384577668.us-east-1.elb.amazonaws.com"
amg_workspace_url = "https://g-668c15280e.grafana-workspace.us-east-1.amazonaws.com"
amp_workspace_id = "ws-8034cbc9-0894-487b-888c-3859fccba6b8"
ci_role_arn = "arn:aws:iam::277802554323:role/emerald-grove-prod-ci"
ecr_repository_url = "277802554323.dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod"
ecs_cluster_name = "emerald-grove-prod-cluster"
ecs_service_name = "emerald-grove-prod-service"
rds_endpoint = "emerald-grove-prod-db.cgrk8yc6a9k1.us-east-1.rds.amazonaws.com:5432"
tofu_role_arn = "arn:aws:iam::277802554323:role/emerald-grove-prod-tofu"
```

Note: An initial apply failed due to `count` depending on a not-yet-known AMP endpoint string. Fixed by adding a `enable_adot_sidecar` boolean variable to the ECS module. Also, the Identity Center user creation failed (cross-account org-managed identity store) — switched to `data.aws_identitystore_user` lookup instead of `resource.aws_identitystore_user` creation.

## 4.3 Deploy Application

```text
$ podman build -f Containerfile -t 277802554323.dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod:1c590e4 .
Successfully tagged 277802554323.dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod:1c590e4

$ podman push 277802554323.dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod:1c590e4
Writing manifest to image destination

$ aws ecs register-task-definition ... (2 containers: emerald-grove-app + adot-collector)
New task definition: arn:aws:ecs:us-east-1:277802554323:task-definition/emerald-grove-prod:7

$ aws ecs update-service --cluster emerald-grove-prod-cluster --service emerald-grove-prod-service ...
ECS deployment triggered
```

Note: Dagger deploy had ECR auth issues, so the image was built and pushed manually with podman. The ECS task definition update was done via AWS CLI.

## 4.4 App Health & ADOT Sidecar Logs

```text
$ curl http://emerald-grove-prod-alb-384577668.us-east-1.elb.amazonaws.com/actuator/health
{"groups":["liveness","readiness"],"status":"UP"}
```

ADOT sidecar logs (CloudWatch `/ecs/emerald-grove-prod`, stream `adot/adot-collector/7ab334fb...`):

```text
2026-04-12T16:54:28.306Z  info  prometheusremotewriteexporter: starting prometheus remote write exporter
2026-04-12T16:54:28.311Z  info  Starting aws-otel-collector... Version: v0.47.0
2026-04-12T16:54:28.312Z  info  Extension started: sigv4auth
2026-04-12T16:54:28.313Z  info  Scrape job added: spring-boot
2026-04-12T16:54:28.313Z  info  Everything is ready. Begin running and processing data.
```

Initial scrape failures (app still starting) resolved after ~30s.

## 4.5 Verify Metrics in AMP

```text
$ mise exec -- awscurl --service aps --region us-east-1 \
  "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-8034cbc9-.../api/v1/query?query=up"

{"status":"success","data":{"resultType":"vector","result":[
  {"metric":{"__name__":"up","instance":"localhost:8080","job":"spring-boot"},"value":[1776020070,"1"]}
]}}
```

```text
$ mise exec -- awscurl --service aps --region us-east-1 \
  ".../api/v1/query?query=http_server_requests_seconds_count"

{"status":"success","data":{"resultType":"vector","result":[
  {"metric":{"__name__":"http_server_requests_seconds_count","method":"GET","status":"200","uri":"/owners/find",...},...},
  ...multiple endpoints...
]}}
```

```text
$ mise exec -- awscurl --service aps --region us-east-1 \
  ".../api/v1/query?query=jvm_memory_used_bytes"

{"status":"success","data":{"resultType":"vector","result":[
  {"metric":{"__name__":"jvm_memory_used_bytes","area":"nonheap",...},"value":[...,"2150912"]},
  ...multiple memory pools...
]}}
```

## 4.6 AMG Dashboard

Dashboard URL: `https://g-668c15280e.grafana-workspace.us-east-1.amazonaws.com/d/emerald-grove-overview/`

```text
$ curl -sf ".../api/search?type=dash-db" -H "Authorization: Bearer $SA_TOKEN"
[{"id":1,"uid":"emerald-grove-overview","title":"Emerald Grove — Overview",...}]
```

Data source configured:

```text
$ curl -sf ".../api/datasources" -H "Authorization: Bearer $SA_TOKEN"
[{"name":"Amazon Managed Prometheus","type":"prometheus","uid":"prometheus",
  "url":"https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-8034cbc9-.../",
  "jsonData":{"sigV4Auth":true,"sigV4AuthType":"ec2_iam_role","sigV4Region":"us-east-1"}}]
```

4 panels confirmed: Request Latency (p50/p95/p99), Error Rate, Throughput, JVM Heap Usage.

## 4.7 Teardown

```text
$ mise run teardown -- --confirm

Step 1/3: Destroying infrastructure...
Destroy complete! Resources: 43 destroyed.

Step 2/3: Emptying state bucket...
All versions deleted. State bucket emptied.

Step 3/3: Destroying state backend...
Destroy complete! Resources: 5 destroyed.

======================================
  Teardown complete!
======================================
```

All 48 resources destroyed cleanly (43 infrastructure + 5 bootstrap).
