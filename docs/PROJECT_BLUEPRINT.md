# Project blueprint

## Project purpose

The MVP answers one question: “Did a watched stock cross my configured threshold, and is the quote data current enough to trust?” It collects stock observations, stores history, visualizes freshness, and sends Discord alerts.

Stock prices are the primary scope. News is phase two to provide context after the stock pipeline is reliable. K-pop events, automated trading, AI sentiment, and a custom rule engine are out of scope for the MVP.

## How this advances the previous project

The previous Kubernetes Monitoring repository reads Kubernetes API objects and exports cluster state to Prometheus/Grafana. It already demonstrates Docker, Kubernetes, Helm, GitHub Actions hosted runners, GHCR, Argo CD, Prometheus, Grafana, basic tests, and Trivy.

This project reuses those foundations but changes the workload and increases depth:

- From observing Kubernetes objects to operating a scheduled, stateful data workload.
- From a local cluster only to Terraform-managed AWS networking, IAM, EC2, k3s, and persistent storage.
- From image build and GitOps sync to a reviewed Terraform plan/apply path and explicit state ownership.
- From a cluster dashboard to operational SLI signals: latest successful collection, data age, accepted/duplicate/rejected records, Job outcome, and alert delivery.
- From merely adding scans to defining what each gate blocks and proving it with controlled failure cases.

The new AWS and Terraform parts count as experience only after they are run and verified. The repository currently contains planning/starter material, not proof of a completed cloud deployment.

## Is the Python collector DevOps work?

The code that calls a market API, parses quote responses, normalizes stock fields, and evaluates stock-specific rules is application/data-engineering work. In a company, that logic would normally belong to a backend or data engineer.

A DevOps engineer may write a small collector or automation script when needed to create and operate a workload. The DevOps evidence is how it is packaged, configured, scheduled, secured, observed, recovered, and delivered—not the amount of finance logic in Python.

For this portfolio, keep the collector intentionally small. Spend most effort on AWS/Terraform, CI/CD controls, Kubernetes/Argo CD operations, and monitoring. A planning allocation is: AWS/Terraform 35%, CI/CD and delivery controls 20%, Kubernetes/Helm/Argo CD 20%, observability and reliability 20%, collector business logic 5%. This is a prioritization guide, not a claim about completed work.

## Data reliability: what can be controlled and shown

The free provider's quota, delays, and outages are external constraints. Do not claim to guarantee the provider. Show that the client respects documented limits and handles failures predictably:

- Schedule requests within the published quota with a safety margin.
- Set connect/read timeouts; retry only transient failures with bounded exponential backoff and jitter.
- On HTTP 429, honor Retry-After when supplied; do not retry permanent client errors indefinitely.
- Validate symbol, numeric price, currency, and provider timestamp before storage.
- Store provider observation time separately from collection time.
- Update last-success only after validation and database commit complete.
- Record run status and counts: received, inserted, duplicate, rejected.
- Test with fixtures for duplicate data, timeout, 429, 5xx, malformed payload, and empty response.
- Grafana shows last success, data age, counts, and errors; alerts when data is stale.

These signals demonstrate controlled behavior. They do not prove the external provider's market data is absolutely correct; that requires source comparison or provider guarantees and is outside this low-cost MVP.

## Deduplication / idempotency

For market snapshots, use a unique key based on the provider's stable observation identity—normally symbol, source, and provider observation timestamp. Store with an upsert/ON CONFLICT policy. Replaying the same fixture should leave the row count unchanged and increase a duplicate counter.

Do not use collection time as the only deduplication key: fetching the same provider snapshot twice would then create two records. Alert deduplication is separate from data deduplication.

## CronJob metrics in this design

Prometheus normally pulls metrics from an endpoint at intervals. A short-lived CronJob may start and exit between scrapes, so a metrics endpoint inside that process is not reliably scrapeable.

MVP choice:
- Use kube-state-metrics to observe whether the Kubernetes Job succeeded, failed, or is overdue.
- Record application-specific collection outcomes in PostgreSQL.
- Let Grafana query PostgreSQL for data freshness and received/inserted/duplicate/rejected counts; use Prometheus for Kubernetes, node, and Pod health.
- Do not add Pushgateway in the first version.

If custom collector metrics must appear in Prometheus later, add a small long-running exporter that reads the latest run summary from PostgreSQL. Pushgateway is another option for batch-job metrics, but it adds stale-series lifecycle management.

## Recruiter-facing proof

Do not present this as production AWS experience before it exists. A convincing portfolio should include a reproducible demo and evidence:

- Terraform plan and approved apply workflow with AWS identity scope explained.
- AWS network diagram, security group rules, IAM role permissions, and state backend ownership.
- Successful GitHub Actions run, scanned immutable image, and Argo CD sync.
- Grafana screenshots with useful values and a demonstrated stale-data alert.
- Failure table showing input condition, expected handling, observed result, and recovery.
- Cost boundary and single-EC2/k3s limitations.

This supports junior/transition DevOps applications by showing work beyond the previous local monitoring project. It does not by itself establish senior-level professional experience.
