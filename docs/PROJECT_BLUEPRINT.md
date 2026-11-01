# 프로젝트 분석과 설계 기준

## 메인 목적

관심 종목의 가격과 관련 뉴스를 수집해 저장하고, 사용자가 정한 단순한 조건에 맞으면 Discord로 알리는 개인 모니터링 서비스를 만든다. Grafana에서 업무 데이터와 운영 상태를 함께 확인한다.

사용자 문제는 관심 정보가 여러 사이트에 흩어져 있어 반복해서 확인해야 한다는 점이다. Watchlist와 규칙에 따라 필요한 정보를 모아 보여주고 확인이 필요한 조건을 알린다. 금융 투자 권유나 자동 매매는 범위 밖이다.

## 이전 프로젝트에서 이번 프로젝트로 확장되는 점

| 영역 | 기존 Kubernetes Monitoring에서 확인한 구현 | 새로 확장할 역량 |
|---|---|---|
| Kubernetes | Kubernetes API에서 Pod, Deployment, Namespace, Warning Event 조회 | 외부 업무 데이터를 처리하는 서비스와 스케줄 작업 운영 |
| Python | Kubernetes 데이터를 Prometheus 형식으로 노출하는 exporter | 외부 소스 수집, 정규화, 재시도와 중복 방지 |
| Prometheus / Grafana | exporter scrape, PromQL 대시보드 | 운영 지표와 PostgreSQL 업무 데이터를 함께 조회하고 알림 |
| Helm / Argo CD | Helm chart를 GitOps로 배포 | 앱, DB, 수집 작업과 모니터링 구성 배포 |
| GitHub Actions / GHCR | ubuntu-latest hosted runner, manifest 검사, 조건부 이미지 빌드, Trivy, GHCR, image tag 갱신 | Terraform 검사·plan·승인 apply, OIDC 기반 AWS 접근 |
| 테스트 | exporter pytest | 수집 결과, 재실행, API 오류, 규칙 평가 검증 |
| 인프라 | Docker Desktop Kubernetes와 kind 실습 | Terraform으로 AWS EC2 기반 k3s 구성 |

새 프로젝트는 Kubernetes 모니터링 exporter에서 데이터 처리 서비스를 운영하는 쪽으로 확장한다. GitHub Actions와 GitOps 경험은 재사용하고, AWS IaC, PostgreSQL, 데이터 수집, DevSecOps를 추가한다.

파일이 존재하는 것과 실제로 실행·검증한 경험은 구분해야 한다. 새 프로젝트가 아직 계획 단계이므로 AWS/Terraform/DevSecOps를 완료된 기술로 소개하지 않는다.

## 채용 담당자 관점

주니어/전환 DevOps 포지션에 기존 프로젝트와 구별되는 근거를 제공할 수 있다. 가치는 도구 개수가 아니라 다음 흐름을 실제로 시연하고 설명할 수 있는지에 달려 있다.

- 외부 소스 → collector → PostgreSQL → Grafana/Discord
- 잘못된 입력, API 오류, 중복 실행, 데이터 지연의 처리
- PR 검사가 위험한 변경을 막고 이미지와 commit을 추적
- AWS 변경은 plan과 승인 절차를 거치고 IAM 권한은 제한
- 알림이 실제 조건에서 발생하고 대응 절차를 제공

이 프로젝트가 실무 AWS 경력을 대신하지는 않는다. 다만 end-to-end로 실행하고 검증하면 전환 포트폴리오를 강화한다.

## 시니어 엔지니어 관점에서 설계에 넣을 것

1. **한 가지 사용 목적**: MVP는 주식 + 관련 뉴스. K-pop은 후속 데이터 소스로 분리한다.
2. **데이터 신뢰성**: API 이용 조건, 호출 한도, timeout, retry/backoff, deduplication, 마지막 수집 시각과 stale 상태를 다룬다.
3. **재실행 안전성**: 같은 데이터 재수집이 중복 행·중복 알림을 만들지 않게 한다.
4. **업무 데이터/운영 지표 분리**: 가격·뉴스는 PostgreSQL, 실행 성공/실패·지속시간·마지막 성공은 Prometheus 계열 지표.
5. **CronJob 메트릭**: 짧은 Job은 scrape 전에 끝날 수 있다. Job 상태는 kube-state-metrics로, 배치 custom metrics는 Pushgateway를 검토한다. Pushgateway의 stale series와 grouping label을 관리해야 한다.
6. **알림 품질**: data freshness, no-data/error, repeat interval, grouping, runbook을 정의한다.
7. **DevSecOps**: PR secret/dependency/code/IaC/image 검사, severity 기준과 예외 절차를 둔다.
8. **AWS 권한**: GitHub OIDC, 제한된 role, PR plan, 보호된 승인 후 apply.
9. **런타임 보안**: k3s API 비공개, 최소 RBAC, non-root, 불필요 capability 제거, resource limits, 제한된 네트워크 노출.
10. **한계·비용 투명성**: 단일 EC2는 단일 장애 지점이며 HA라고 부르지 않는다. 예상 사용비와 정지/정리 절차를 기록한다.

## 현재 결정과 미정 사항

- 결정: Stock + News 우선, K-pop 후순위.
- 결정: Grafana를 MVP 운영 화면으로 사용, 별도 Web UI 없음.
- 결정: PostgreSQL은 업무 데이터, Prometheus는 운영 데이터.
- 결정: MVP 알림은 Discord 하나.
- 미정: API 제공자/이용 조건/무료 한도/호출 간격.
- 미정: CronJob 주기와 custom metric 전달 방식.
- 미정: AWS 리전, EC2 크기, host 접근, 비용 상한.
- 제외: 초기 Rule Engine, AI sentiment, 자동 매매, EKS, 다중 노드 HA.

보안과 아키텍처 가이드는 계획 상태다. 구현과 검증이 끝난 후에만 완료 표현을 쓴다.
