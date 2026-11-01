# DevOps Event Intelligence Platform

A stock-watchlist monitoring service that collects price observations, stores them in PostgreSQL, and alerts when a configured threshold is crossed. The first release focuses on stock data. Related news is a later extension; K-pop events are out of scope for the MVP.

The project is designed to demonstrate how a DevOps engineer can provision, deliver, observe, and operate a stateful workload on AWS without EKS.

> Status: starter repository. The collector, AWS resources, Kubernetes workloads, and alert rules are planned, not yet implemented or verified.

## User outcome

Track a small watchlist without repeatedly checking provider sites. See the latest quote, source timestamp, and collection freshness in Grafana. Receive a Discord alert when a configured rule is met. This is a monitoring tool, not investment advice or automated trading.

## Architecture

~~~mermaid
flowchart TB
  Dev[WSL development] --> Git[GitHub repository]
  Git --> Runner[GitHub-hosted Actions]
  Runner -->|checks and image scan| GHCR[GHCR]
  Runner -->|Terraform plan, gated apply via OIDC| TF[Terraform]
  TF -->|VPC, network rules, IAM, EC2, data volume| AWS[AWS]
  TF --> State[(S3 Terraform state)]
  AWS --> Host[EC2 Linux host]
  Host --> K3s[k3s]
  Git -->|Argo CD pulls desired state| Argo[Argo CD]
  Argo --> K3s
  GHCR --> K3s
  API[Stock data provider] --> Job[Stock collector CronJob]
  K3s --> Job
  Job --> DB[(PostgreSQL)]
  KSM[kube-state-metrics] --> Prom[Prometheus]
  K3s --> Prom
  DB --> Grafana[Grafana]
  Prom --> Grafana
  Grafana --> Discord[Discord]
~~~

Terraform manages AWS infrastructure. Argo CD manages Kubernetes workloads. GitHub Actions validates and builds; Terraform apply is gated. AWS values remain placeholders in [AWS_CONNECTIONS.md](docs/AWS_CONNECTIONS.md).

## Operational proof

The project will demonstrate reliability with evidence the operator controls:

- Preserve both the provider's observation time and the time the collector stored the record.
- Validate required fields and reject malformed or stale observations.
- Replay the same fixture twice and prove the database uniqueness rule prevents duplicate rows.
- Simulate timeout, HTTP 429, HTTP 5xx, and invalid payloads; show the recorded result and alert behavior.
- Dashboard latest successful collection, data age, accepted/duplicate/rejected counts, and Kubernetes Job status.
- Keep the collection schedule below the selected free plan's published limit; handle provider limits rather than claiming to control them.

## DevOps focus

- **AWS / Terraform:** custom VPC, subnet and routing, security groups, IAM instance profile, EC2/k3s host, dedicated PostgreSQL data volume, remote Terraform state.
- **CI/CD:** GitHub-hosted runner, validation and security gates, immutable GHCR image tags, reviewed Terraform plan and approved apply.
- **Kubernetes / GitOps:** Helm, Argo CD, resource sizing, probes, Job history/cleanup, persistent storage, least-privilege RBAC.
- **Observability:** Prometheus for cluster and Kubernetes Job state; Grafana for Prometheus and PostgreSQL data, freshness panels, and Discord alerts.
- **Python:** a deliberately small collector workload. The portfolio emphasis is its reliable packaging, scheduling, monitoring, and operation—not building a large finance application.

## Storage and cost boundary

PostgreSQL storage target: **2 GiB maximum backing volume**. A PVC request of 2Gi alone may not enforce physical disk usage for every StorageClass. The final design must use a backing volume that enforces capacity and alert before it fills. PostgreSQL WAL, indexes, and temporary files share that space, so usable quote history will be smaller than 2 GiB.

No AWS resources have been created. EC2, storage, network egress, and other AWS resources may incur charges; confirm the budget before applying Terraform. No apply, deletion, or paid service is part of this starter setup.

## Planned delivery stages

1. Confirm the stock API's terms, free-tier request limit, timestamps, and response behavior.
2. Build and verify the stock collection flow locally with fixtures and PostgreSQL.
3. Add idempotent storage, Grafana views, and one threshold alert.
4. Package and run the collector as a Kubernetes CronJob in local kind.
5. Add deep Helm/Argo CD, Prometheus/Grafana, and failure-observation work.
6. Build the AWS network and EC2/k3s foundation with Terraform and a reviewed GitHub Actions workflow.
7. Verify the full path from PR to AWS, GitOps deployment, collection, dashboard, and alert.

See [project blueprint](docs/PROJECT_BLUEPRINT.md), [MVP specification](docs/MVP_SPEC.md), [implementation plan](docs/IMPLEMENTATION_PLAN.md), [CronJob metrics explanation](docs/CRONJOB_METRICS.md), and [AWS connection checklist](docs/AWS_CONNECTIONS.md), plus the [Kubernetes layout](kubernetes/README.md).

