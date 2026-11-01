# MVP 요구사항

## 사용자 흐름

1. 운영자가 watchlist에 symbol, 가격 조건, 뉴스 키워드를 설정한다.
2. collector가 설정된 주기로 외부 소스를 조회한다.
3. 필요한 필드만 정규화해 PostgreSQL에 저장한다.
4. 조건을 만족하면 Discord로 알린다.
5. Grafana에서 가격·뉴스와 collector/cluster 상태를 확인한다.

## 기능 범위

- 주식 가격 스냅샷 수집
- 관련 뉴스 제목, 출처, URL 수집
- 가격 임계치 또는 키워드 규칙
- Discord 알림
- PostgreSQL 업무 데이터 및 Prometheus 운영 지표를 Grafana에서 확인
- 출처와 수집 시각 표시

## 저장 필드 초안

- Price: symbol, source, price, currency, change_percent, observed_at, collected_at
- News: source, source_id 또는 canonical_url, title, published_at, collected_at, matched_symbol
- Collection run: source, started_at, finished_at, status, records_seen, records_stored

기사 전체, 불필요한 부가정보, API 응답 전체는 기본 저장하지 않는다. 실제 API 필드를 확인한 뒤 schema를 확정한다.

## 완료 기준

- API 또는 fixture의 가격/뉴스 데이터가 DB에 저장된다.
- 반복 수집으로 중복 레코드가 생기지 않는다.
- 가격/키워드 조건에 맞는 Discord 알림이 발생한다.
- API 오류 시 성공으로 기록하지 않고 마지막 성공 시각을 갱신하지 않는다.
- 오래된 데이터가 Grafana에서 식별된다.
- API/AWS credential이 Git에 들어가지 않는다.
- 이미지가 commit SHA로 추적되며 Terraform apply는 plan 확인과 승인 뒤 실행된다.

## API 선정 전 확인

공식 이용 약관과 요금 정보를 확인하고 개인/상업 이용, 무료 한도, 데이터 지연, 뉴스 재배포 조건, API key, rate limit, timeout/error 동작을 비교한다. 현재 특정 API의 무료 제공을 가정하지 않는다.

## MVP에서 제외

- AI sentiment와 복합 가격+뉴스 추론
- 자체 Rule Engine
- 자동 매매
- K-pop collector
- 별도 Web UI
