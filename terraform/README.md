# Terraform and deployment status

Terraform is intended to create the AWS foundation for the Event Intelligence Platform. Ansible is intended to install k3s and bootstrap Argo CD. Argo CD will then deploy the Kubernetes applications from this repository.

## Responsibility split

| Path / component | Intended responsibility | Current state |
|---|---|---|
| `terraform/bootstrap` | Create the S3 bucket used for remote Terraform state and configure its protection | Draft; state persistence for the bootstrap run is unresolved |
| `terraform/infra` | Create the VPC, subnet, internet route, security group, EC2, IAM instance profile, and PostgreSQL EBS volume | Draft; static configuration errors remain |
| GitHub Actions | Validate, run Terraform, and pass EC2 details to Ansible | OIDC identity check succeeded, but the Terraform workflow wiring is incomplete |
| Ansible | Connect to EC2, install k3s, then install Argo CD | Draft; host and access details are not connected |
| Argo CD | Sync Kubernetes applications from Git | Manifests exist; AWS deployment is not verified |

## Intended deployment flow

1. Prepare the Terraform state bucket.
2. Run `terraform/infra` with that bucket as its S3 backend and create AWS resources.
3. Read the EC2 public IP, instance ID, and security group ID from Terraform outputs.
4. Provide those values and the selected connection method to Ansible.
5. Ansible installs k3s and bootstraps Argo CD on EC2.
6. Argo CD pulls the Kubernetes manifests and deploys PostgreSQL, collectors, Prometheus, and Grafana.

The OIDC identity test only confirms that GitHub Actions can assume the AWS role. It does not confirm that Terraform resources were applied, that Ansible can connect, or that workloads are running.

## Blocking items found in the current Terraform configuration

### State bucket and bootstrap state

`terraform/bootstrap/state.tf` creates `seob-bucket`, but `terraform/bootstrap/terraform.tf` has no remote backend. Terraform therefore keeps the bootstrap state in a local `terraform.tfstate` file. A GitHub-hosted runner is temporary, so that state disappears when its job ends. A later bootstrap run would not know that it already created the bucket.

The bucket itself must exist before `terraform/infra` can run `terraform init` with it as a backend. The bootstrap sequence needs a durable state plan: for example, create the bucket once as a deliberate bootstrap step, then use it for the infrastructure state. Do not configure a Terraform root to create its own backend bucket during the same first `init`.

The bootstrap provider currently has `region = eu-central-1`; the region value needs to be a quoted string. The DynamoDB table resource is still active even though a nearby comment says it is disabled. The infrastructure backend uses S3 `use_lockfile`; the DynamoDB table is not connected to that backend.

### Infrastructure backend

`terraform/infra/terraform.tf` currently uses `region = var.aws_region` inside the backend block. Terraform backend settings cannot reference input variables, locals, or data sources. Use a literal region or provide the backend setting during `terraform init`. The S3 bucket must already exist when `init` runs. [Terraform backend configuration rules](https://developer.hashicorp.com/terraform/language/backend)

### Resource references and HCL

The current `terraform/infra` files contain references that prevent a clean validation/apply:

- `network.tf` refers to `aws_pvc.seob_vpc`; the resource declared above it is `aws_vpc.seob_vpc`.
- `network.tf` has `tags { ... }` on the security group; Terraform map syntax requires `tags = { ... }`.
- `iam.tf` spells the role trust policy principal key `indentifiers`; it must be `identifiers`.
- `storage.tf` refers to `aws_instance.sebo_vm`; the EC2 resource is named `aws_instance.seob_vm`.
- The route and route-table-association blocks have `tags` arguments that are not supported by those AWS provider resources. [Route resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) · [Route-table association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)
- `compute.tf` and `iam.tf` use the S3 bucket resource `aws_s3_bucket.seob_s3`, but that resource is declared only in the separate `terraform/bootstrap` root. Terraform roots do not share resource references directly. CloudTrail also needs a bucket policy that permits log delivery; the current configuration does not define one.

The AWS state bucket and CloudTrail log bucket should have distinct purposes. PostgreSQL files are intended for EBS, not S3. Attaching EBS to EC2 does not automatically make a Kubernetes PVC use it: the current PostgreSQL StorageClass uses `rancher.io/local-path`, so the EBS mount and Kubernetes storage configuration still need to be connected.

### GitHub Actions workflow wiring

The current workflow references also need alignment before deployment can be considered automated:

- `CI.yaml` defines `terraform_boot` and `terraform_infra` outputs, while `terraform-validate` checks `needs.changes.outputs.terraform`, which is not defined.
- `terraform-validate` runs in `terraform/`, but the actual configurations are separate roots in `terraform/bootstrap/` and `terraform/infra/`. Each root needs its own init/validate step.
- `CI.yaml` calls `.github/workflows/terraform_bootstrap_cd.yaml`, while the repository file is named `terraform_boot_cd.yaml`.

### EC2 to Ansible connection

`terraform/infra/outputs.tf` currently exposes the EC2 public IP and instance ID, but the deployment flow does not pass them into the Ansible inventory. The security group ID is not an output, although `ansible_cd.yaml` expects it as a secret. `ansible/inventory.ini` still contains `<ec2 public ip>`.

The connection method also needs one consistent choice:

- **SSH:** the current Ansible workflow uses a private SSH key, but `compute.tf` does not configure an EC2 key pair. Terraform must register the matching public key and attach its key-pair name to the instance. The workflow then needs the private key and current host/security group details.
- **SSM:** the EC2 role includes the SSM managed policy, but the Ansible inventory and workflow are currently written for SSH. To use SSM, configure the Ansible SSM connection/plugin and pass the instance ID; an SSH private key and inbound port 22 are not the SSM connection method.

The EC2 instance profile is for AWS permissions used by the instance. It is separate from the GitHub Actions OIDC role used by Terraform.

## Current assessment

The repository has the intended infrastructure outline, but Terraform and Ansible are not yet ready to treat deployment as complete. Fix the state/bootstrap path, the listed Terraform references, CI validation and reusable-workflow paths, then connect Terraform outputs to the chosen Ansible access method. No AWS apply or Ansible deployment was performed during this review.

Review the Terraform plan and expected AWS charges before applying. The EC2, EBS, public IP/networking, and CloudTrail resources can incur costs.


