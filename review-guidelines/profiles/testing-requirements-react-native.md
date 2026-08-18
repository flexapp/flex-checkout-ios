# Testing Requirements — React Native
**MANDATORY** for AI generation and AI PR review.

These requirements apply to React Native applications that run on:
- Mobile (iOS/Android)
- Web (React Native Web)

These requirements are enforced in PR review by AI and **MUST** be followed by all AI code generation.

---

## Repo Context / Toolchain
- **Test runner:** Jest with `jest-expo` preset
- **UI testing:** `@testing-library/react-native` + `@testing-library/jest-native`
- **Network mocking:** MSW (Mock Service Worker) — recommended deterministic network mocking approach
- **Navigation:** React Navigation (`@react-navigation/native`, `@react-navigation/stack`)
- **State management:** Zustand for local stores and `@tanstack/react-query` for server-state fetching/caching
- **Jest setup:** Uses `setupFilesAfterEnv` and `legacyFakeTimers: true`. Tests should align with those conventions.

---

## 0) Non-Negotiable Rules

### MUST
- Add or update tests for all behavior changes (features, bug fixes, refactors that can change behavior).
- Keep tests deterministic and stable.
- Prefer behavior assertions over implementation details.
- Ensure cross-platform behavior is covered when code is shared.

### MUST NOT
- Rely on wall-clock time, live network, or unseeded randomness.
- Write snapshot-only tests for behavior changes.
- Over-mock to the point that the test would pass even if the real behavior is broken.

If a PR contains no tests, it **MUST** include an explicit justification in the PR description and a follow-up plan.

---

## 1) Test Types (Required)

### A) Unit Tests (logic-level)
**Definition:** Isolated tests for pure functions / hooks / small components without real network.

**MUST be added when:**
- Business logic changes
- Validation / formatting rules change
- Branch-heavy logic changes
- Hooks behavior changes (state transitions, derived values)

**MUST cover:**
- Happy path
- At least one edge case
- Meaningful branches (if/else, switch cases, error handling)

**Tools / guidance**
- Use **Jest** (with `jest-expo` preset). Run via workspace scripts (e.g., `yarn workspace mobile test` or `yarn test`).
- For hooks prefer `@testing-library/react-hooks` or test via a small component harness.
- Use legacy Jest fake timers per repo config when testing timer-based behavior; ensure timers are properly restored.

**Forbidden patterns:**
- Asserting on internal function call order unless it is the behavior.
- Full snapshots as the only assertion.

---

### B) Unit API Integration Tests (API boundary)
**Definition:** Exercises API client usage + request/response handling + error mapping, using deterministic mocked network (no live calls).

**MUST be added when:**
- API client code changes
- Request/response mapping changes
- Error handling changes (timeouts, auth, retries, 4xx/5xx mapping)
- Any code that consumes API responses changes meaningfully

**MUST cover:**
- Success response mapping
- 400/401/403 behavior where applicable
- 404/409 where applicable
- 5xx and network failure mapping
- Loading + failure state if UI consumes the API directly

**Network mocking**
- **MSW (recommended)**: Use `msw/node` in Jest tests for deterministic mocking.
- Acceptable alternatives: fetch/axios mocks with fixed fixtures.
- **Forbidden:** Real HTTP requests or tests that depend on external services or internet availability.

---

### C) Unit Functional Tests (feature flow within app boundary)
**Definition:** Tests a user-facing behavior across multiple components/modules in a test harness (not full E2E).

**MUST be added when:**
- A feature flow changes (navigation, state machine, multi-step UI)
- Cross-module behavior changes (store + screen + API integration)
- Regressions are likely without flow-level coverage

**MUST cover:**
- A complete happy-path flow outcome
- At least one negative flow (validation error, permission denied, API error)
- Assertions on final observable outcomes (UI, state changes, emitted events)

**Tools / guidance**
- Use **React Native Testing Library** for mobile/web component/screen testing; for purely web components use `@testing-library/react` where appropriate.
- For navigation flows, use screen-level tests and either mock navigation props or use a small test navigator harness using React Navigation.

**Forbidden patterns:**
- Giant "do everything" tests that are slow and fragile.
- Testing intermediate internal state excessively instead of user-visible outcomes.

---

## 2) Cross-Platform Requirements (Mobile + Web)

### Shared code MUST be tested in at least one platform harness
- If behavior is platform-agnostic, tests **MAY** run once in a shared environment.
- If behavior differs by platform (e.g., `Platform.select`, web-only props, gesture differences), tests **MUST** include platform-specific coverage.

**MUST cover platform divergences when present:**
- Accessibility differences
- Keyboard/focus interactions (web)
- Press/gesture differences (mobile)
- Navigation differences if any

---

## 3) Minimum Required Coverage (for any change)

For any new feature or behavior change, tests **MUST** include:

1. Happy path
2. Invalid input OR error case
3. Authorization/permission case (if applicable)
4. Edge/boundary case
5. Failure/exception path (if meaningful)

Omitting any item requires explicit justification in the PR description.

---

## 4) Determinism & Flake Prevention (Strict)

### Time
**MUST** freeze/mock time for:
- timers, debounces, polling, animations dependent on timers
- date/time formatting logic

Follow repo Jest fake timers conventions (`legacyFakeTimers: true`) when needed.

### Randomness
**MUST** seed or remove randomness.

### Network
**MUST** mock network at the boundary (MSW or deterministic fetch/axios mocks).
**MUST NOT** call live services.

### Async
**MUST** await observable outcomes (UI updates, state transitions).
**MUST NOT** use arbitrary sleeps.

---

## 5) Mocking Requirements (Strict)

### Acceptable mocking
- External boundaries: network, storage, OS/device APIs, device capabilities
- Analytics/event emitters (assert "event emitted" as outcome)

### Forbidden over-mocking
AI **MUST** fail review if:
- The unit under test is mocked (test doesn't exercise real logic)
- The test asserts only that functions were called (without asserting behavior)
- The test would pass if the real implementation were removed

---

## 6) Naming & Structure Requirements

Tests **MUST**:
- Use descriptive names: `should <behavior> when <condition>`
- Follow Arrange / Act / Assert (or Given/When/Then)
- Keep one primary behavioral reason to fail per test

---

## 7) AI PR Review Requirements (Mandatory)

When reviewing a PR, AI **MUST**:

### A) Verify required test types exist
- Logic changes → Unit tests required
- API boundary changes → Unit API integration tests required
- Feature flow changes → Unit functional tests required

### B) Fail review if any are true
- Branches are uncovered without justification
- Tests rely on real time, randomness, or live network
- Excessive mocking hides real behavior
- Only snapshot tests were added for behavioral changes
- Cross-platform divergence exists but isn't tested

### C) Comment format
AI comments **MUST** include:
- What is missing/violated
- Where (file/area)
- Which rule in this doc was violated
- Concrete fix suggestion

**Example comments**
- "Missing Unit API integration test for 401 mapping in `src/api/user.ts`. Violates §1B + §7B."
- "This test uses real timers; freeze time. Violates §4."
- "Snapshot-only test for a feature change is not allowed. Violates §1A/§1C."

---

## 8) AI Code Generation Requirements

When generating code:
- AI **MUST** generate the required tests as part of the change
- AI **MUST** choose the correct test type(s)
- AI **MUST NOT** defer tests unless explicitly instructed
- If uncertain, AI **MUST** prefer a higher-level but still fast test (often Unit Functional with RNTL)

This document overrides any conflicting guidance.
