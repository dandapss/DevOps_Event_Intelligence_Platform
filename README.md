# Event Intelligence Platform

A personal DevOps project for collecting stock prices and related news on a schedule, storing the results in PostgreSQL, and operating the workloads on Kubernetes. Stock data is the main scope; this project does not provide investment advice or place trades.

## Architecture

```mermaid
flowchart TB
  Dev[Developer] --> Repo

  subgraph GitHub[GitHub]
    Repo[Project repository]
    Actions[GitHub Actions]
    GHCR[GHCR container images]
    Repo --> Actions
    Actions -->|Build and publish changed collectors| GHCR
  end

  subgraph Local[Local development - kind]
    ArgoLocal[Argo CD]
    subgraph LocalCluster[Kubernetes workloads]
      LStock[Stock collector CronJob]
      LNews[News collector CronJob]
      LDB[PostgreSQL]
      LProm[Prometheus]
      LGraf[Grafana]
    end
    ArgoLocal --> LocalCluster
    LStock --> LDB
    LNews --> LDB
  end

  Repo -. GitOps manifests .-> ArgoLocal
  GHCR -->|Image pull| LStock
  GHCR -->|Image pull| LNews
  StockAPI[Stock data provider] --> LStock
  NewsRSS[Yahoo Finance RSS] --> LNews

  subgraph AWS[AWS production target - not yet verified]
    TF[Terraform configuration]
    VPC[VPC and public subnet]
    EC2[EC2 Linux host]
    K3s[k3s cluster]
    ArgoAWS[Argo CD]
    subgraph AWSCluster[Kubernetes workloads]
      PStock[Stock collector CronJob]
      PNews[News collector CronJob]
      PDB[PostgreSQL]
      PProm[Prometheus]
      PGraf[Grafana]
    end
    TF --> VPC --> EC2 --> K3s --> ArgoAWS --> AWSCluster
    PStock --> PDB
    PNews --> PDB
  end

  GHCR -. Future image pull .-> PStock
  GHCR -. Future image pull .-> PNews
  StockAPI -.-> PStock
  NewsRSS -.-> PNews

  classDef source fill:#e8f1ff,stroke:#356ac3,color:#172b4d
  classDef github fill:#f0eaff,stroke:#7048a8,color:#2d1b45
  classDef local fill:#e8f7ef,stroke:#31845b,color:#163c2b
  classDef target fill:#fff3df,stroke:#c17a16,color:#50330d
  class Dev,StockAPI,NewsRSS source
  class Repo,Actions,GHCR github
  class ArgoLocal,LocalCluster,LStock,LNews,LDB,LProm,LGraf local
  class TF,VPC,EC2,K3s,ArgoAWS,AWSCluster,PStock,PNews,PDB,PProm,PGraf target
```

The AWS box shows the declared production target, not a completed deployment. Dashed arrows mark target or external connections.

## Project status

- The repository contains Python stock and news collectors, container build definitions, Kubernetes manifests, and Helm configuration for PostgreSQL and monitoring components.
- GitHub Actions is configured for path-based validation and collector image publishing to GHCR.
- Local kind is the development target. AWS EC2/k3s is described as a target, not a completed deployment.
- The Terraform files are still being prepared. See [Terraform notes](terraform/README.md) for the resources and current configuration limits.
- Grafana dashboard and alert work is not presented here as complete.

## Storage and cost

The Terraform configuration declares an encrypted 2 GiB EBS volume for PostgreSQL. The S3 bucket is for Terraform state and serves a separate purpose. Review the Terraform plan and AWS charges before applying resources.

## Project notes

- [Project blueprint](docs/PROJECT_BLUEPRINT.md)
- [MVP specification](docs/MVP_SPEC.md)
- [Implementation plan](docs/IMPLEMENTATION_PLAN.md)
- [AWS setup checklist](docs/AWS_CONNECTIONS.md)
- [Terraform notes](terraform/README.md)

