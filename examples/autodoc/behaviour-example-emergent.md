## `[BHV-e41f]` Account lockout amplification under concurrent retry

### Classification

| Field          | Value |
|----------------|-------|
| **Category**   | `emergent` |
| **Source**      | `implementation` |
| **Significance** | `critical` |
| **Status**     | `validated` |

### Description

When a customer has multiple active sessions (e.g., browser + mobile app) and enters an incorrect password, each session independently triggers the login retry flow. The auth service's failed-attempt counter increments per attempt regardless of session origin, so two sessions retrying concurrently can lock the account in half the expected attempts. This behaviour was discovered during load testing — no requirement specifies it, and the auth and session components each behave correctly in isolation.

This is an interaction between the **session management** layer (which permits concurrent sessions) and the **brute-force protection** layer (which counts raw attempts). Neither component is buggy; the emergent behaviour is the problem.

### Trigger

Two or more active sessions submit failed login attempts for the same account within the failed-attempt counting window (15 minutes).

### Actors

- **Customer** — has multiple active sessions
- **Auth Service** — validates credentials, increments failed-attempt counter
- **Session Manager** — maintains concurrent session state
- **Rate Limiter** — enforces per-account attempt thresholds

### Contracts

#### Preconditions

- Account exists and is not already locked
- Customer has 2+ active sessions (browser, mobile, API token refresh)
- Failed-attempt counter is below the lockout threshold (5)

#### Postconditions

- Account locks when the counter reaches 5, regardless of how many sessions contributed
- All active sessions receive a `401 account_locked` on their next request
- Customer receives a single unlock email (deduplicated by the notification service)

#### Invariants

- Failed-attempt counter is atomically incremented (no lost updates under concurrency)
- Lock decision is made on the authoritative counter value, not a session-local cache
- Unlock flow is independent of session count

#### Failure modes

| Condition | System response | Postcondition |
|-----------|-----------------|---------------|
| Counter increment races with a successful login from another session | Last-write-wins: if success is recorded after the 5th failure, account remains locked (correct — the successful login predated the lock check) | Account locked; successful session is invalidated |
| Notification service deduplication fails | Customer receives multiple unlock emails | Account locked; multiple valid unlock tokens exist (all work, first use unlocks) |

### Scenarios

#### Happy path (single session — no amplification)

> **Given** an account with 0 failed attempts
> **When** a customer enters the wrong password 4 times from one browser session
> **Then** the counter is 4 and the account is not locked
> **And** the 5th failure locks the account

#### Amplified lockout (two sessions)

> **Given** an account with 0 failed attempts
> **When** the customer enters the wrong password 3 times in the browser
> **And** simultaneously enters the wrong password 2 times in the mobile app
> **Then** the counter is 5 and the account is locked
> **And** both sessions receive `401 account_locked` on their next request
> **And** the customer perceives being locked out after only 3 attempts (from the browser's perspective)

#### Race between failure and success

> **Given** an account with 4 failed attempts
> **When** the mobile app submits the correct password (attempt counter not incremented)
> **And** the browser simultaneously submits an incorrect password (counter → 5)
> **Then** the account is locked
> **And** the mobile session that just authenticated is invalidated

### Traceability

#### Requirements

- None — this behaviour is not specified in any requirement. It emerges from the interaction of:
  - [US-102] "Allow concurrent sessions on multiple devices"
  - [NFR-008] "Lock account after 5 failed login attempts within 15 minutes"

#### Code references

- `services/auth/login.go:Authenticate` — increments counter without session-awareness (line 87)
- `services/auth/rate_limiter.go:CheckAndIncrement` — atomic counter increment, no session dedup (line 34)
- `services/session/manager.go:ActiveSessions` — permits unbounded concurrent sessions (line 112)

#### Test references

- `services/auth/login_test.go:TestConcurrentFailedAttempts_LockoutAmplification` — added after discovery
- **Missing**: no integration test covering the race between concurrent success + failure

### Notes

**Discovered via**: load test simulating multi-device users with typo-prone passwords. Not caught in unit tests because auth and session components are tested in isolation.

**Possible mitigations** (not yet implemented):
1. Count failed attempts per-session, lock only when a single session exceeds threshold — but this weakens brute-force protection if attacker rotates sessions
2. Deduplicate attempts within a short window (e.g., 2s) by account — reduces accidental amplification without weakening security
3. Document as accepted behaviour and adjust the lockout UX to show the customer how many attempts remain across all sessions

**Related behaviours**: `BHV-7c2a` (payment retry) — same pattern of retry amplification when multiple actors retry independently against a shared counter.
