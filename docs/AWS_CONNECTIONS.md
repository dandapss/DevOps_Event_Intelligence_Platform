# AWS 연결 전 체크리스트

현재 AWS 계정에 연결하지 않았고, 리소스를 생성·변경·삭제하지 않았다. 아래 표식은 연결 전 채울 자리다.

## 계정과 비용
- 계정 ID: [AWS 연결 - 'AWS Account ID']
- 리전: [AWS 연결 - 'AWS Region']
- 월 비용 한도와 경고 기준: [AWS 연결 - 'Monthly budget and alert threshold']
- 계정 접근 주체/MFA: [AWS 연결 - 'AWS identity and MFA method']

## GitHub Actions → AWS
- GitHub owner/repository: [AWS 연결 - 'GitHub owner and repository']
- IAM OIDC provider ARN: [AWS 연결 - 'GitHub OIDC provider ARN']
- Terraform plan/apply role ARN: [AWS 연결 - 'Terraform IAM role ARN']
- 허용할 repository, branch, environment: [AWS 연결 - 'OIDC trust conditions']
- 보호된 GitHub Environment 승인 규칙: [AWS 연결 - 'Environment approval policy']

기본 방향은 장기 AWS access key 대신 OIDC 임시 자격 증명을 사용하고, role 권한과 trust 조건을 최소 범위로 제한하는 것이다.

## Terraform state
- S3 bucket 이름: [AWS 연결 - 'Terraform state bucket name']
- state key: [AWS 연결 - 'Terraform state key']
- backend 리전/encryption/versioning: [AWS 연결 - 'State backend settings']
- state lockfile 설정: [AWS 연결 - 'S3 lockfile setting']
- backend/OIDC 초기 bootstrap 방법: [AWS 연결 - 'Bootstrap procedure']

S3 backend bucket은 아직 생성하지 않았다. Terraform이 backend를 사용하기 전에 bootstrap 순서를 정해야 한다.

## EC2 / k3s
- EC2 AMI, 크기, subnet: [AWS 연결 - 'EC2 AMI, instance type, and subnet']
- EC2 instance profile: [AWS 연결 - 'EC2 instance profile and scoped permissions']
- host 접근(SSM 또는 제한 SSH): [AWS 연결 - 'Host access method']
- DNS/TLS: [AWS 연결 - 'Domain and TLS termination']
- k3s API 접근 제한: [AWS 연결 - 'K3s API access restriction']

K3s API를 인터넷 전체에 공개하지 않는다. SSH/SSM 선택 시 필요한 네트워크와 비용을 먼저 확인한다.

## 외부 API와 runtime secret
- Stock API와 credential 저장 방식: [AWS 연결 - 'Stock API and secret storage']
- News source와 credential 저장 방식: [AWS 연결 - 'News source and secret storage']
- Discord webhook 저장 방식: [AWS 연결 - 'Discord webhook secret storage']

API key와 webhook을 Git, image layer, Terraform 변수 파일, 로그에 넣지 않는다. 유료 secret 서비스는 요금을 확인하기 전 사용하지 않는다.
