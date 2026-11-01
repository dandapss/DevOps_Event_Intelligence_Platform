# Terraform directory

Terraform will manage AWS infrastructure. Argo CD will manage Kubernetes application resources after k3s and Argo CD are bootstrapped.

Planned workflow:
1. GitHub-hosted runner checks format, validation, and IaC security.
2. Pull request produces a Terraform plan for review.
3. A protected GitHub Environment gates apply.
4. Actions assumes a restricted AWS role through OIDC.
5. Terraform stores state in a versioned S3 backend with state locking.
6. GHCR and Argo CD deliver application images and Kubernetes configuration.

The backend, OIDC provider, IAM roles, EC2 settings, region, and cost limit are not configured. No credentials or actual AWS resource names belong here.

The provider version is constrained in versions.tf. After terraform init, commit .terraform.lock.hcl so local WSL and GitHub-hosted runners use the same provider selection. Never commit .terraform/, state files, or real .tfvars. Do not run apply until plan and cost are reviewed.
