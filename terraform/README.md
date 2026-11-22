# Terraform and AWS

This directory defines the AWS foundation for the Event Intelligence Platform. Terraform owns AWS infrastructure and its state. Ansible prepares the EC2 host; Argo CD manages Kubernetes resources after it is installed.

## Two Terraform roots

terraform/backend and terraform/infra are independent Terraform root modules. Each directory has its own provider/backend configuration and its own state key. They share an S3 bucket, but they do not share Terraform resource addresses.

| Root | Purpose | State key |
|---|---|---|
| terraform/backend | Creates and protects the Terraform state bucket | backend.tfstate |
| terraform/infra | Describes the network, EC2 host, IAM, and instance outputs | infra.tfstate |

The bucket has versioning, AES-256 server-side encryption, and S3 Block Public Access enabled. The S3 bucket stores Terraform state; it is separate from the EBS volume used for PostgreSQL data.

A Terraform resource address such as aws_s3_bucket.seob_s3 is visible only inside the root where it is declared. The fact that both roots use the same S3 backend does not make the bucket resource address available to terraform/infra. Roots share values through explicit interfaces such as input variables, data sources, or remote-state outputs; the shared backend bucket does not merge their resource graphs.

## State bootstrap flow

The bucket must exist before a root can use it as its backend. The one-time bootstrap workflow therefore:

1. Initializes terraform/backend with -backend=false, using temporary local state.
2. Creates the S3 bucket and its protection settings.
3. Reinitializes with state migration so the bootstrap state is stored in backend.tfstate.

Later backend changes use the normal remote-state workflow. The infrastructure root uses the same bucket with the separate key infra.tfstate.

## AWS infrastructure design

~~~mermaid
flowchart TB
  subgraph State["Terraform state"]
    BackendRoot["terraform/backend root"]
    StateBucket["S3 state bucket<br/>versioning, encryption, public access block"]
    BackendState[("backend.tfstate")]
    InfraState[("infra.tfstate")]
    BackendRoot -->|Creates| StateBucket
    StateBucket --> BackendState
    StateBucket --> InfraState
  end

  subgraph Infra["terraform/infra root"]
    VPC[VPC]
    Subnet[Public subnet]
    IGW[Internet Gateway]
    Route[Default internet route]
    SG[Security group]
    EC2["Ubuntu 24.04 EC2<br/>t3.micro default<br/>20 GiB encrypted gp3 root disk<br/>IMDSv2 required"]
    Role["EC2 role and instance profile<br/>SSM, CloudWatch, EBS CSI permissions"]
    Outputs["Instance ID and public IP outputs"]

    VPC --> Subnet
    VPC --> IGW
    IGW --> Route
    Subnet --> Route
    Subnet --> EC2
    SG --> EC2
    Role --> EC2
    EC2 --> Outputs
  end

  Infra --> InfraState
  EC2 --> Ansible[Ansible host setup]
  Ansible --> K3s[K3s]
  K3s --> ArgoCD[Argo CD]
  ArgoCD --> EBSCSI[EBS CSI driver]
  EBSCSI --> PVC["PostgreSQL PVC requests 2 Gi"]
  PVC --> EBS["Encrypted gp3 EBS volume"]
~~~

The PostgreSQL data path is Kubernetes-driven: its PVC uses the AWS StorageClass, and the EBS CSI driver creates and mounts the volume. Terraform declares the EC2 and IAM foundation rather than a PostgreSQL EBS volume or attachment.

## Resource responsibilities

| Component | Responsibility |
|---|---|
| Terraform backend root | S3 bucket, versioning, encryption, and public-access blocking |
| Terraform infrastructure root | VPC, public subnet, Internet Gateway, route, security group, EC2, instance profile, and outputs |
| EC2 instance profile | SSM and CloudWatch access, plus the permissions used by the EBS CSI driver |
| Ansible | Install K3s and Argo CD; the root Application is bootstrapped manually once |
| EBS CSI and StorageClass | Create and connect PostgreSQL's EBS volume from the PVC request |
| Argo CD | Reconcile Kubernetes resources declared in Git |

The EC2 role currently attaches AmazonEBSCSIDriverPolicy. In this single-node K3s design, the driver uses the EC2 instance identity. This is a deliberate simplicity trade-off: instance-profile access should be treated as a node-level security boundary, and Pod access to EC2 metadata should be restricted.

## Workflow and change control

The initial backend setup is exposed as a manual workflow. It initializes the backend root without connecting to S3, creates the bucket using temporary local state, then migrates that state to the S3 backend. After this one-time bootstrap, changes under `terraform/backend/` use the normal remote-state workflow.

On `main`, changes under `terraform/backend/` or `terraform/infra/` call their matching Terraform workflow. Each workflow definition runs `terraform plan` followed by `terraform apply --auto-approve`. After an infrastructure apply, the workflow is configured to call Ansible to install K3s and Argo CD. The operator then applies `kubernetes/argocd/root-app.yaml` once with `kubectl`. The root Application points at `kubernetes/`; that directory's Kustomization includes both the root Application manifest and the child Application manifests, so Argo CD keeps all of them aligned with Git after bootstrap.

Application image changes follow a separate path: GitHub Actions builds the changed collector image, publishes a commit-SHA tag to GHCR, and updates the corresponding Kubernetes image tag. Argo CD then reconciles the Git change.

## Design choices

- A single public subnet and EC2 instance keep the first AWS environment small and easy to reason about. The security group declares outbound access and no inbound rule; SSM is the intended management channel.
- The EC2 root disk is separate from PostgreSQL's database volume.
- The PostgreSQL PVC requests 2Gi. The EBS CSI StorageClass provisions an encrypted gp3 volume from that request.
- There is no Terraform-managed attachment for PostgreSQL. The CSI driver owns attach and mount operations, avoiding two controllers managing the same attachment.

## Files

- backend/terraform.tf — Terraform version, AWS provider, and S3 backend key.
- backend/state.tf — state bucket protections.
- infra/terraform.tf — Terraform version, AWS provider, and infrastructure state key.
- infra/network.tf — VPC, subnet, Internet Gateway, route, and security group.
- infra/compute.tf — EC2 instance configuration.
- infra/iam.tf — EC2 role, instance profile, and attached policies.
- infra/variables.tf — region, CIDRs, Availability Zone, and instance type.
- infra/outputs.tf — instance ID and public IP for host configuration
