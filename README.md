# Event Intelligence Platform

A DevOps portfolio project built around a scheduled stock-data service. Python collectors retrieve market data, PostgreSQL stores the observations, and Kubernetes runs the collectors as CronJobs. The project focuses on the delivery and operation of that service: infrastructure as code, CI, GitOps, persistent storage, and monitoring components.

## Why this project

Provisioning a cluster is only the starting point. The central problem here is keeping a small stateful data pipeline repeatable: collect on a schedule, store records safely, and make infrastructure and application changes traceable through Git.

The design separates the responsibilities:

- Terraform describes AWS infrastructure and the remote state bucket.
- Ansible prepares the EC2 host and installs K3s and Argo CD.
- Argo CD reconciles Kubernetes resources from this repository.
- GitHub Actions validates changes and builds only the collector images affected by source changes.
- PostgreSQL stores application data; Prometheus and Grafana are platform monitoring components.

## Architecture

~~~mermaid
flowchart TB
  Developer[Developer] --> Repo[Git repository]

  subgraph Delivery[GitHub delivery]
    direction TB
    Repo --> Actions[GitHub Actions]
    Actions -->|Build changed collector| GHCR[GHCR image]
    Actions -->|Commit SHA image tag| Repo
  end

  Repo -. GitOps manifests .-> ArgoCD[Argo CD]
  Terraform[Terraform] --> VPC[VPC and public subnet]
  VPC --> EC2[Ubuntu EC2]
  Ansible[Ansible] --> K3s[K3s]
  EC2 --> K3s
  K3s --> ArgoCD

  subgraph Cluster[Kubernetes on EC2]
    direction TB
    ArgoCD --> Stock[Stock CronJob]
    ArgoCD --> News[News CronJob]
    ArgoCD --> PostgreSQL[PostgreSQL]
    ArgoCD --> EBSCSI[EBS CSI driver]
    ArgoCD --> Monitoring[Prometheus and Grafana]
    Stock --> PostgreSQL
    News --> PostgreSQL
    PostgreSQL --> PVC[2 Gi PVC]
    PVC --> SC[Encrypted gp3 StorageClass]
    EBSCSI -->|Creates and mounts| EBS[(EBS volume)]
    EBS --> PostgreSQL
  end

  GHCR -->|Image pull| Stock
  GHCR -->|Image pull| News
  StockSource[Stock data provider] --> Stock
  NewsSource[Yahoo Finance RSS] --> News
  Terraform -. State keys .-> S3[(S3 state bucket)]

  classDef github fill:#f0eaff,stroke:#7048a8,color:#2d1b45
  classDef cloud fill:#e8f1ff,stroke:#356ac3,color:#172b4d
  classDef workload fill:#e8f7ef,stroke:#31845b,color:#163c2b
  classDef storage fill:#fff3df,stroke:#c17a16,color:#50330d
  class Repo,Actions,GHCR github
  class Terraform,VPC,EC2,Ansible,K3s,ArgoCD cloud
  class Stock,News,PostgreSQL,Monitoring workload
  class PVC,SC,EBSCSI,EBS,S3 storage
~~~

## Design decisions

### Storage ownership

PostgreSQL declares its storage need through a 2 Gi PVC. The EBS CSI driver provisions an encrypted gp3 EBS volume from the AWS StorageClass, then handles attachment and mounting for the Pod. Terraform supplies the EC2 and IAM foundation; it does not create or attach PostgreSQL's data volume.

This keeps the Kubernetes storage request and its AWS volume lifecycle together. It also avoids Terraform and Kubernetes both trying to control the same EBS attachment. The StorageClass uses Retain so deleting a claim does not automatically discard database data.

### Separate Terraform state scopes

The S3 bucket is Terraform's state storage, not PostgreSQL storage. The backend root creates and protects the bucket; the infrastructure root stores its state under a different key in that bucket. Each root has its own resource graph and state.

### Short-lived collectors

The stock and news collectors run as separate CronJobs, with different schedules. This isolates their execution and lets each image be rebuilt when its own source changes.

## Repository map

- src/ — Python collector applications and Dockerfiles.
- kubernetes/ — Argo CD Applications, Helm wrapper charts, CronJobs, and Kubernetes configuration.
- terraform/backend/ — S3 bucket and Terraform backend bootstrap.
- terraform/infra/ — AWS network, EC2, IAM, and instance outputs.
- ansible/ — K3s and Argo CD host setup.
- .github/workflows/ — change detection, validation, image publishing, and infrastructure workflow definitions.
- docs/ — project blueprint, MVP scope, implementation plan, and AWS connection decisions.

## Delivery flow

A source change builds the matching collector image and publishes a commit-SHA tag to GHCR. GitHub Actions updates the Kubernetes image tag in Git, and Argo CD reconciles that Git change on the cluster.

Infrastructure and application delivery have separate paths: Terraform describes AWS resources, Ansible configures the EC2 host, and Argo CD manages Kubernetes workloads. This separation makes each change's owner and scope visible in the repository.

## Operating boundaries

The design uses one EC2 K3s node and a 2 Gi PostgreSQL volume. It keeps the learning environment small and understandable; it is not a high-availability database design.

The current repository uses example database credentials in Kubernetes configuration. For an AWS environment, provide them through a Kubernetes Secret rather than committing real credentials to Git.
