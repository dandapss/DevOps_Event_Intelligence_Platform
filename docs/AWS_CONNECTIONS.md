# AWS 연결 전 체크리스트

현재 AWS 계정에 연결하지 않았고, 리소스를 생성·변경·삭제하지 않았다. 아래 값은 실제 연결 전에 채울 placeholder다.

## 계정과 비용
- AWS 계정 ID: [AWS 연결 - 'AWS Account ID']
- 리전과 가용 영역: [AWS 연결 - 'AWS Region and Availability Zone']
- 월 비용 상한/경고 기준: [AWS 연결 - 'Monthly budget and alert threshold']
- 접근 계정, MFA, 사용 가능한 role: [AWS 연결 - 'AWS identity, MFA, and permitted role']

## Terraform state 및 GitHub OIDC
- Terraform state S3 bucket/key: [AWS 연결 - 'S3 state bucket and key']
- versioning/encryption/lockfile: [AWS 연결 - 'State bucket protection settings']
- GitHub owner/repository와 허용 branch/environment: [AWS 연결 - 'GitHub repository trust conditions']
- IAM OIDC provider ARN: [AWS 연결 - 'GitHub OIDC provider ARN']
- Terraform plan/apply role ARN 및 정책: [AWS 연결 - 'Terraform IAM role ARN and least-privilege policy']
- OIDC/backend bootstrap 방법: [AWS 연결 - 'Initial bootstrap procedure']
- GitHub protected Environment 승인 규칙: [AWS 연결 - 'Apply approval policy']

장기 AWS key를 GitHub secrets에 저장하지 않고 OIDC 임시 자격 증명을 쓰는 방향이다. Role trust와 permission은 저장소, branch/environment, 실제 관리 리소스에 한정한다.

## AWS network와 EC2
- Custom VPC CIDR: [AWS 연결 - 'VPC CIDR']
- Public subnet CIDR 및 route/Internet Gateway: [AWS 연결 - 'Subnet and internet route']
- EC2 AMI/instance type/public IP 선택: [AWS 연결 - 'EC2 image, size, and public address']
- Security Group inbound/outbound: [AWS 연결 - 'Allowed ingress and egress']
- host 접근 방식(SSM 또는 제한 SSH): [AWS 연결 - 'Host access method']
- EC2 instance profile: [AWS 연결 - 'EC2 role and required permissions']
- DNS/TLS 종료 지점: [AWS 연결 - 'Domain and TLS termination']
- K3s API를 외부에 공개하지 않는 접근 방식: [AWS 연결 - 'Private k3s API access']

MVP 계획은 NAT Gateway를 두지 않는 저비용 단일 EC2 구성이다. 외부 API 접근, 이미지 pull, 관리 접근에 필요한 egress가 가능한지 확인해야 한다. 실제 적용 전에 네트워크 노출과 예상 요금을 검토한다.

## PostgreSQL storage
- 전용 EBS volume 크기 목표: [AWS 연결 - 'PostgreSQL data volume: 2 GiB']
- EBS volume type/AZ/attachment: [AWS 연결 - 'EBS type, AZ, and attachment']
- k3s StorageClass 또는 host mount 설계: [AWS 연결 - 'Storage provisioner and mount path']
- 70/85% 사용량 알림 기준 확인: [AWS 연결 - 'Disk usage warning and critical thresholds']

2GiB는 PostgreSQL data directory의 물리 backing volume 한도다. WAL, index, temporary files도 이 공간을 사용하므로 실제 quote 데이터는 더 적게 저장할 수 있다. Kubernetes PVC request만으로 물리 사용량이 제한된다고 가정하지 않는다.

## Stock provider / Discord secret
- Stock provider, free quota, data delay and terms: [AWS 연결 - 'Selected stock provider and verified free-plan terms']
- API key 보관 방식: [AWS 연결 - 'Stock API secret storage']
- Discord webhook 보관 방식: [AWS 연결 - 'Discord webhook secret storage']

외부 API key와 webhook은 Git, Terraform state/plan, container image, 로그에 넣지 않는다. 유료 secret 관리 서비스를 선택하기 전에는 요금을 확인한다.
