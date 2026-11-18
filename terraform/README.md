# Terraform Infrastructure

This document covers only the Terraform roots and AWS resources declared under `terraform/`. The diagrams show configuration intent; they do not mean the AWS resources have been applied or verified.

## Terraform layout

```mermaid
flowchart TB
  subgraph Bootstrap[Bootstrap root - terraform/bootstrap]
    BTF[Terraform bootstrap configuration]
    S3[ S3 bucket: seob-bucket ]
    Versioning[Bucket versioning enabled]
    Encryption[Default encryption: SSE-S3 / AES256]
    PublicBlock[Block public access]
    BState[(Bootstrap state object)]
    BTF --> S3
    S3 --> Versioning
    S3 --> Encryption
    S3 --> PublicBlock
    S3 -. Stores .-> BState
  end

  subgraph Infra[Infrastructure root - terraform/infra]
    Variables[Region, CIDRs, AZ, instance type]
    VPC[VPC 10.10.0.0/16]
    Subnet[Public subnet 10.10.10.0/24]
    IGW[Internet Gateway]
    RT[Route table: 0.0.0.0/0 to IGW]
    Association[Subnet route association]
    SG[Security group: all outbound IPv4]
    EC2["Ubuntu 24.04 EC2<br/>t3.micro default<br/>Public IPv4<br/>20 GiB encrypted gp3 root disk<br/>IMDSv2 required"]
    Role[EC2 IAM role and instance profile]
    SSM[AmazonSSMManagedInstanceCore]
    CW[CloudWatchAgentServerPolicy]
    EBS["2 GiB encrypted gp3 EBS<br/>attached as /dev/sdf"]
    Outputs["Outputs: instance public IP<br/>instance ID<br/>PostgreSQL volume ID"]
    CloudTrail[CloudTrail]

    Variables --> VPC
    VPC --> Subnet
    VPC --> IGW
    VPC --> RT
    RT --> Association
    IGW --> RT
    Subnet --> Association
    Subnet --> EC2
    SG --> EC2
    Association --> EC2
    Role --> EC2
    Role --> SSM
    Role --> CW
    EC2 --> EBS
    EC2 --> Outputs
    EBS --> Outputs
  end

  S3 -. Backend bucket configured in infra .-> InfraState[("Infra state key:<br/>terraform/terraform.tfstate")]
  CloudTrail -. Current reference points to the bootstrap root resource .-> S3

  classDef root fill:#edf2ff,stroke:#4263a5,color:#172b4d
  classDef storage fill:#e9f7ef,stroke:#31845b,color:#163c2b
  classDef network fill:#e8f1ff,stroke:#356ac3,color:#172b4d
  classDef compute fill:#fff3df,stroke:#c17a16,color:#50330d
  classDef security fill:#f8eafa,stroke:#914c9c,color:#3b1d42
  classDef output fill:#f1f3f5,stroke:#68717a,color:#20262b
  class Bootstrap,Infra,BTF,Variables root
  class S3,Versioning,Encryption,PublicBlock,BState,InfraState,EBS storage
  class VPC,Subnet,IGW,RT,Association,SG network
  class EC2 compute
  class Role,SSM,CW,CloudTrail security
  class Outputs output
```

## Declared resources

### `terraform/bootstrap`

- Creates the `seob-bucket` S3 bucket.
- Enables bucket versioning, AES256 server-side encryption, and S3 Block Public Access.
- Declares an S3 backend for bootstrap state.

### `terraform/infra`

- Creates a VPC, one public subnet, an Internet Gateway, a default internet route, and a route-table association.
- Creates an EC2 security group with unrestricted outbound IPv4 and no inbound rules declared in this Terraform configuration.
- Creates an Ubuntu 24.04 EC2 instance with a public IPv4 address, a 20 GiB encrypted gp3 root disk, and IMDSv2 required.
- Creates an EC2 role/profile with `AmazonSSMManagedInstanceCore` and `CloudWatchAgentServerPolicy` attached.
- Creates an encrypted 2 GiB gp3 EBS volume and attaches it to EC2 as `/dev/sdf`.
- Declares outputs for the instance public IP, instance ID, and EBS volume ID.
- Declares a CloudTrail resource.

## State layout

Both roots are configured to use `seob-bucket`, with different state keys intended to keep their state separate:

- `infra`: `terraform/terraform.tfstate`
- `bootstrap`: the current `terraform/bootstrap/terraform.tf` contains two backend declarations with different keys. Resolve that duplicate before using the configuration.

The S3 backend stores Terraform state; it does not create its own bucket. The bucket resource is declared in the bootstrap root.

## Current configuration limits

- The bootstrap `.tf` files currently contain duplicated resource/backend blocks and `---` separator lines. As written, they need cleanup before Terraform can validate or run.
- The CloudTrail configuration in `terraform/infra/compute.tf` refers to `aws_s3_bucket.seob_s3`, which is declared in a different Terraform root. Terraform roots do not share resource addresses directly. The current CloudTrail bucket reference is therefore not a valid cross-root connection.
- Terraform only attaches the EBS volume. The current Terraform files do not format or mount it, nor connect it to a Kubernetes PVC.
- The diagrams describe declared Terraform configuration only. No Terraform validation, plan, or AWS apply was run while updating this README.

