# 구현 순서

## 0. 범위 결정
- 한 문장 사용자 목적과 가격/뉴스 규칙을 확정한다.
- API 후보의 공식 이용 조건, 요청 제한, 비용을 비교한다.
- 수집 주기, 데이터 보존 기간, 필요한 필드를 정한다.
- AWS 월 비용 한도와 경고 기준을 정한다.
- 이 단계에서는 AWS 리소스를 만들지 않는다.

## 1. 로컬 데이터 흐름
- kind에서 PostgreSQL을 실행한다.
- fixture를 이용해 collector 정규화와 DB 저장을 구현한다.
- 중복 저장, 잘못된 입력, API 실패 동작을 검증한다.
- 실제 API는 선정과 이용 조건 확인 후 연결한다.

## 2. 규칙, Grafana, 알림
- 단순 가격 또는 키워드 조건 하나를 먼저 end-to-end로 구현한다.
- Discord 알림을 확인한다.
- PostgreSQL 업무 데이터와 Prometheus 운영 데이터를 Grafana에서 구분한다.
- stale data와 collector 실패 알림 및 runbook을 작성한다.
- CronJob이면 kube-state-metrics와 Pushgateway 적용 범위를 결정한다.

## 3. 패키징과 GitOps
- Docker image와 Helm chart를 만든다.
- kind에서 Argo CD가 Git 설정을 sync하는지 확인한다.
- runtime secret을 Git 평문으로 저장하지 않는다.

## 4. CI / DevSecOps
- PR에서 Python checks, tests, secret scan, dependency scan을 실행한다.
- YAML/Helm/Terraform 검증과 IaC scan을 실행한다.
- 앱 코드 변경에만 image build/scan을 수행하고 SHA tag를 사용한다.
- main apply는 protected GitHub Environment 승인 뒤 수행한다.
- Actions 권한을 최소화하고 가능한 경우 action을 immutable SHA로 pin한다.

## 5. AWS / Terraform
- AWS 계정, 리전, 접근 방식, 비용 한도를 확인한 뒤 계획한다.
- Terraform S3 backend와 OIDC/IAM role bootstrap 순서를 정한다.
- GitHub-hosted runner에서 OIDC 기반 plan을 수행한다.
- 승인 후에만 apply한다.
- Terraform은 AWS, Argo CD는 Kubernetes 앱 리소스를 관리한다.
- cloud-init은 k3s/Argo CD의 최초 설치에 한정한다.

## 6. 종단 간 검증
- PR → image → GHCR → Argo sync → collector → PostgreSQL → Grafana → Discord를 시연한다.
- API 오류, stale data, 잘못된 설정을 넣어 CI/alert를 확인한다.
- 실제 비용, single-node 한계, 복구 runbook을 문서화한다.

완료라고 쓰기 전 모든 흐름을 실제로 실행해 증거를 남긴다.
