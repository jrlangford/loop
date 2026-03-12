## `[BHV-7c2a]` Payment retry with escalating backoff

### Classification

| Field          | Value |
|----------------|-------|
| **Category**   | `specified` |
| **Source**      | `design` |
| **Significance** | `critical` |
| **Status**     | `implemented` |

### Description

When a payment charge attempt fails with a retryable error, the system retries up to three times with exponentially increasing delays before marking the payment as failed and notifying the customer. This prevents transient gateway issues from causing unnecessary payment failures while bounding the retry window to avoid double-charges on delayed gateway responses.

### Trigger

A payment gateway returns a retryable error code (`gateway_timeout`, `rate_limited`, `temporary_unavailable`) in response to a charge request.

### Actors

- **Payment Service** — initiates and retries charge attempts
- **Payment Gateway** (external) — processes the charge
- **Notification Service** — sends failure notification to customer
- **Idempotency Store** — tracks charge attempt keys to prevent double-charges

### Contracts

#### Preconditions

- Payment has a valid idempotency key assigned before the first attempt
- Customer has at least one valid payment method on file
- The error code returned by the gateway is in the retryable set

#### Postconditions

- On success: payment status is `charged`, exactly one charge appears on the customer's statement
- On exhausted retries: payment status is `failed`, zero charges appear, customer receives a failure notification with a retry link
- In all cases: every attempt is logged with its idempotency key, timestamp, and gateway response

#### Invariants

- The idempotency key remains constant across all retry attempts for the same payment
- At most one successful charge exists per idempotency key (enforced by gateway + idempotency store)
- Total retry window does not exceed 70 seconds (1s + 4s + 16s + buffer)

#### Failure modes

| Condition | System response | Postcondition |
|-----------|-----------------|---------------|
| Gateway returns non-retryable error (e.g., `card_declined`) | No retry; immediate failure | Payment status = `failed`, customer notified with decline reason |
| Idempotency store is unavailable | Abort without charging | Payment status = `pending_retry`, alert to on-call, no customer notification yet |
| Notification service is unavailable after final failure | Payment marked `failed`, notification queued for retry independently | Payment status = `failed`, notification status = `queued` |

### Scenarios

#### Happy path

> **Given** a payment of $49.99 with idempotency key `pay_8f3a`
> **When** the first charge attempt returns `gateway_timeout`
> **And** the second attempt (after 1s delay) returns `200 OK`
> **Then** payment status is `charged`
> **And** exactly one charge of $49.99 appears in the gateway ledger under key `pay_8f3a`
> **And** no failure notification is sent

#### All retries exhausted

> **Given** a payment of $49.99 with idempotency key `pay_8f3a`
> **When** all four attempts (initial + 3 retries) return `gateway_timeout`
> **Then** payment status is `failed`
> **And** zero charges appear in the gateway ledger
> **And** customer receives an email with subject "Payment failed" containing a retry link

#### Non-retryable error on first attempt

> **Given** a payment of $49.99 with idempotency key `pay_8f3a`
> **When** the first charge attempt returns `card_declined`
> **Then** no retry is attempted
> **And** payment status is `failed`
> **And** customer receives a notification with the decline reason

### Traceability

#### Requirements

- [US-234] As a customer, I want failed payments to be retried automatically so I don't have to re-enter my card details for transient errors
- [US-251] As a customer, I want to be notified when a payment fails permanently so I can take action
- [NFR-012] Payment retries must not exceed 3 attempts with exponential backoff

#### Code references

- `services/payment/charge.go:RetryCharge` — retry loop and backoff calculation
- `services/payment/idempotency.go:EnsureKey` — idempotency key assignment and lookup
- `services/payment/gateway_client.go:IsRetryable` — retryable error classification

#### Test references

- `services/payment/charge_test.go:TestRetryCharge_ExponentialBackoff`
- `services/payment/charge_test.go:TestRetryCharge_NonRetryableError_NoRetry`
- `services/payment/charge_test.go:TestRetryCharge_AllRetriesExhausted_NotifiesCustomer`
- `services/payment/integration_test.go:TestRetryCharge_IdempotencyPreventsDuplicateCharge`

### Notes

The 70-second retry window was chosen to stay well under the gateway's idempotency key TTL (24 hours) while still covering most transient outages. If gateway reliability drops below 99.5%, consider adding a circuit breaker — see `BHV-7c2b`.
