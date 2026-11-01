# CronJob and Prometheus metrics

## Why a CronJob's own /metrics endpoint is easy to miss

Prometheus usually scrapes a live HTTP endpoint on a schedule. A CronJob may run for a few seconds and exit before the next scrape. Once the Pod exits, its in-process metrics endpoint is gone. Therefore “the code increments a Prometheus counter” does not guarantee Prometheus ever collected that value.

## Three choices

1. **Kubernetes Job state (MVP):** kube-state-metrics reads Kubernetes objects and exports Job/Pod status. This answers whether the Job ran, succeeded, failed, or is overdue. It does not know whether the returned stock price was valid.
2. **Application result in PostgreSQL (MVP):** persist last run, status, and counts. Grafana queries this to show data freshness and whether collection produced usable rows.
3. **Custom metrics in Prometheus (later if needed):** use Pushgateway for short-lived batch outcomes or a long-running exporter that reads the run summary. Pushgateway requires stale series cleanup; a separate exporter adds another workload.

For the first version, use choices 1 and 2. This avoids adding a component before the dashboard needs it.
