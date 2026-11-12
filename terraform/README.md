Terraform manages AWS infrastructure for the production environment.

Managed by Terraform:
- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Groups
- IAM Roles / Instance Profile
- EC2 (Linux)
- Cloudflare DNS (planned, if possible)

besides:
- K3S will be deployed by ansible
- argocd will be deployed by ansible or terraform (No idea which is better)

Workflow
1. "Push" by DevOps Engineer or Developer
   - Git

2. GitHub Actions
   - Test the code
   - Check the security
   - Build Image
   - Save in GHCR

3. Terraform 
   - AWS Infrastructure Provisioning

4. Ansible
   - k3s Installation
   - argo cd installation

5. argo cd
   - postgresql
   - grafana
   - stock collector
   - news collector
   - prometheus (if necessary)

6. Grafana
   - Alert which hits the criteria
   - Show necessary information through dashboard


## Some Personal Notes
1. Try to add "terraform validate" and "terraform fmt" in terraform CD
  - terraform validate : It is like lint
  - terraform fmt : It fixes the format of the file
  - terraform fmt needs to go first, because it looks goooood! 
