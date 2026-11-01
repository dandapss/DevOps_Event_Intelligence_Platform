# Kubernetes layer

All Kubernetes configuration is intended to live here and be pulled by Argo CD from Git. These files are starter configuration, not a deployed cluster.

## Ownership and flow

- Terraform provisions AWS networking, IAM, EC2, and the PostgreSQL data volume.
- Cloud-init or a controlled bootstrap installs k3s and Argo CD on EC2.
- Argo CD reconciles Kubernetes objects from this directory.
- Helm packages the collector and PostgreSQL workloads.
- Prometheus observes cluster and Job state; Grafana queries Prometheus and PostgreSQL.

Terraform must not manage the same application objects as Argo CD.

## Planned layout

- base: project Namespace and shared defaults
- policies: storage request limits and later RBAC/NetworkPolicy
- storage: PostgreSQL PVC example and selected StorageClass
- apps: PostgreSQL, stock collector CronJob, monitoring integrations
- argocd: root Application example pointing to the Git repository

The stock provider, collector image, secret mechanism, and storage driver are not selected yet, so no workload chart or CronJob is deployable.

## PostgreSQL storage

The namespace policy limits total PVC requests to 2Gi and allows one claim. A PVC request quota is not automatically a physical byte quota. The AWS design must provide a backing volume that enforces the cap. A dedicated 2Gi EBS volume includes PostgreSQL data, WAL, indexes, and temporary files; the usable quote history is smaller.

The example PVC is not applied. Creating an EBS-backed claim can provision billable storage.
