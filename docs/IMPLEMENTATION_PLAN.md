# Implementation plan

## Stage 1 — Stock behavior, locally
- Select the provider only after checking official free-plan terms and request limits.
- Define the watchlist, quote timestamp semantics, schedule, retention, and threshold.
- Use fixtures first; implement validation, PostgreSQL upsert, run outcome, and duplicate counting.
- Demonstrate duplicate replay and provider-error cases without depending on live API availability.

## Stage 2 — Application operations in kind
- Package the small collector in Docker and run it as a CronJob.
- Use Helm values for schedule, timeout, resources, image tag, and retention settings.
- Use kube-state-metrics for Job state; query stored run/freshness data from PostgreSQL in Grafana.
- Add one threshold notification and one stale-data notification.
- Keep Prometheus for cluster/node/Pod/Job health; do not add Pushgateway initially.

## Stage 3 — Deepen existing tools
- Argo CD owns Kubernetes desired state and sync behavior; test drift, failed sync, rollback of Git configuration, and pruning boundaries.
- Prometheus/Grafana: define useful signals, alert conditions, no-data behavior, dashboard variables, annotations, and runbooks.
- Kubernetes: resource requests/limits, probes for always-on components, Job history/TTL, RBAC, secret references, storage behavior.
- Docker: small image, non-root runtime, pinned base image, reproducible build, image scan, immutable SHA tag.

## Stage 4 — AWS and Terraform
- Design a small custom VPC without a NAT Gateway in the first cost-conscious iteration; verify internet egress and access requirements before deployment.
- Terraform manages VPC, subnet/route, security group, IAM instance profile, EC2, and dedicated PostgreSQL data storage.
- Keep the k3s API private; restrict admin access to the chosen method.
- Store Terraform state remotely; bootstrap the backend and GitHub OIDC role deliberately.
- GitHub-hosted Actions runs fmt/validate/security checks and PR plan; protected approval gates apply.
- EC2 cloud-init installs the minimal k3s/Argo CD bootstrap; Argo CD then owns workload manifests.
- Configure 2Gi physical PostgreSQL backing capacity and alerts before it fills. The PVC request alone is not accepted as proof of a hard cap.

## Stage 5 — End-to-end evidence
- Trace PR → checks → image → GHCR → Argo CD → CronJob → PostgreSQL → Grafana → Discord.
- Capture successful and controlled failure runs.
- Record what AWS resources were actually created, their cost boundary, and teardown procedure before any eventual cleanup.
- Update README with only verified results.

AWS deployment remains gated on [AWS connection details](AWS_CONNECTIONS.md) and cost review.
