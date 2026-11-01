# Terraform directory

Terraform manages the AWS foundation: custom VPC, subnet and routing, security groups, IAM instance profile, EC2 host, and dedicated PostgreSQL data storage. Argo CD manages Kubernetes workloads after k3s bootstrap.

Planned GitHub-hosted runner workflow:
1. Pull request: fmt, validate, IaC security checks, and Terraform plan.
2. Review planned create/update/destroy actions.
3. A protected GitHub Environment gates apply.
4. Actions assumes a restricted AWS role through OIDC; no long-lived AWS keys.
5. Store state remotely in S3 with versioning and locking.

Provider constraints are in versions.tf. Commit .terraform.lock.hcl after init. Never commit .terraform/, state files, or real .tfvars. No AWS resources or backend are created yet; check the budget before apply.
