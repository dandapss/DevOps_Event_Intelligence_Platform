# DevOps Event Intelligence Platform

A personal watchlist service that collects selected market prices and related news, stores them in PostgreSQL, evaluates simple conditions, and sends Discord notifications. Grafana is the operator dashboard; the MVP has no separate web UI.

The engineering goal is to deliver and operate this service through a secure, repeatable workflow: Terraform for AWS infrastructure, GitHub Actions for validation and controlled changes, GHCR for images, and Argo CD for workloads on k3s.

> Status: planning and starter files only. No AWS resources have been created and no live data source has been selected.

## MVP

- Collect a small watchlist of market prices and related headlines.
- Store only fields needed for history, display, and alert evaluation.
- Notify through Discord when a configured price or keyword condition is met.
- Show business data from PostgreSQL and operational health from Prometheus in Grafana.
- Defer K-pop events, sentiment analysis, and a custom rule engine until the stock-and-news flow works.

This is a monitoring tool, not investment advice.

## Planned architecture

~~~mermaid
flowchart TB
  Dev[Developer in WSL2] -->|PR / push| GitHub[GitHub repository]
  GitHub --> Runner[GitHub-hosted Actions runner]
  Runner -->|validate, scan, terraform plan| Review[Review / approval]
  Review -->|OIDC short-lived AWS role| Terraform[Terraform apply]
  Terraform --> AWS[AWS EC2 Linux host]
  Terraform --> State[(S3 remote Terraform state)]
  AWS --> K3s[k3s cluster]
  Runner -->|build and publish on app changes| GHCR[GHCR image]
  GitHub -->|Argo CD pulls Kubernetes config| Argo[Argo CD in k3s]
  GHCR -->|image pull| Workloads[Collectors, PostgreSQL, monitoring]
  Argo --> Workloads
  Sources[External market and news sources] --> Collectors[Scheduled collectors]
  Collectors -->|business records| DB[(PostgreSQL)]
  Collectors -->|batch outcome metrics (method pending)| Metrics[Pushgateway or exporter]
  Metrics --> Prometheus[Prometheus]
  K3s -->|cluster metrics| Prometheus
  DB --> Grafana[Grafana dashboards and alert rules]
  Prometheus --> Grafana
  Grafana -->|notifications| Discord[Discord]
~~~

Terraform owns AWS resources. Argo CD owns Kubernetes application resources. Terraform state is stored separately from Git. The AWS bootstrap, exact data source, and batch-metrics transport are not selected yet.

## Planned security and operations

- GitHub Actions OIDC with a narrowly scoped AWS role; no long-lived AWS keys in Git.
- Review before infrastructure changes are applied.
- Checks for source code, dependencies, container images, and Terraform configuration.
- API credentials outside Git; restricted database access.
- Data freshness and collector outcomes monitored in addition to Pod health.
- Alerts tested and recovery steps documented.

## Environments

- Development: local kind cluster.
- Planned runtime: one AWS EC2 Linux host running k3s.
- CI: GitHub-hosted runners.
- CD: Argo CD pulls Kubernetes configuration from Git and reconciles k3s.

See [project blueprint](docs/PROJECT_BLUEPRINT.md), [MVP requirements](docs/MVP_SPEC.md), [implementation plan](docs/IMPLEMENTATION_PLAN.md), [AWS connection checklist](docs/AWS_CONNECTIONS.md), and [Terraform notes](terraform/README.md).

