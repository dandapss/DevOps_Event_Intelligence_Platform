# MVP specification — stock monitoring

## User outcome

Track selected stocks and receive a Discord notification when a configured price condition is met. Grafana shows the latest observation and whether the data is fresh. The service does not provide investment advice or place trades.

## MVP flow

1. Read a small watchlist and threshold configuration.
2. A Kubernetes CronJob requests the current quote from the selected provider.
3. Validate the response and timestamp.
4. Insert the observation into PostgreSQL idempotently.
5. Evaluate the threshold and send a deduplicated Discord alert.
6. Record the run outcome and expose it through Grafana.

News is a later extension after this stock-only path works.

## Data fields

- symbol
- provider/source
- price and currency
- provider observation timestamp
- collection timestamp
- percent change only if the provider defines its comparison period clearly
- run status and counts for received, inserted, duplicate, and rejected records

The exact schema depends on the selected API's timestamp and quote semantics. Do not store the full response by default.

## Data correctness and verification

- Validate required fields, expected symbol, numeric ranges, currency, and timestamp.
- Reject invalid or out-of-order observations according to a documented rule.
- Keep provider time separate from database collection time.
- Use a database unique constraint for provider observation identity.
- Replay identical fixtures and assert that no additional row is inserted.
- Simulate timeout, HTTP 429, HTTP 5xx, malformed data, and empty results.
- Update last-success only when the DB transaction commits.
- Show last-success time, age in minutes, run outcome, and row counts in Grafana.

The user cannot control provider quota or outages. The client should use only the selected free plan's documented quota, schedule below that limit, add bounded retries/timeouts, and make failures visible.

## API selection gate

Before implementation, compare official provider terms, free request quota, quote delay, timestamp meaning, rate-limit response, outage behavior, key requirement, and permission to display/store data. No provider is selected in this starter version.

## Acceptance criteria

- A valid fixture creates the expected quote row.
- Replaying the same source observation creates no duplicate row.
- Invalid data and provider errors do not update last-success.
- 429, timeout, and transient 5xx behavior is visible and bounded.
- Grafana shows quote history and freshness; a stale-data condition triggers the configured Discord alert.
- A Kubernetes Job failure is distinguishable from a successful job that returned no usable observation.
