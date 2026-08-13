# Testing Requirements (Java — Spring Boot)
**Version:** 1.1 — 2025-01-15
**MANDATORY** for AI generation and AI PR review.

---

## 1. Purpose & Scope
Defines testing expectations for Spring Boot services. Enforced by CODEX (see Section 10). Apply per-service or repo-wide (`testing-requirements-java.md`).

---

## 2. Toolchain (typical)
- Build: **Gradle** or **Maven** (CI runs `./gradlew test` or `mvn test`).
- Test runner: **JUnit 5 (Jupiter)**.
- Mocking: **Mockito**, `mockito-junit-jupiter`.
- Spring test libs: `spring-boot-starter-test`.
- Web tests: `MockMvc`, `WebTestClient`, `TestRestTemplate`.
- Persistence: `@DataJpaTest` + **Testcontainers** (Postgres/MySQL).
- HTTP mocks: **WireMock** / **MockWebServer**.
- Async: **Awaitility**.
- Messaging: `spring-kafka-test` or Testcontainers.

---

## 3. Non-Negotiable Rules
All items below are **MUST**/**MUST NOT** unless explicitly noted.

**MUST**
- Add or update tests for **all** behavioral changes.
- Keep tests deterministic, stable, and reasonably fast.
- Assert observable behavior (not internals). Tests that only snapshot structure without asserting behavior are **insufficient**.
- Mock external boundaries realistically using WireMock/Testcontainers/MockWebServer and ensure consumer tests can run in CI against executable mocks.

**MUST NOT**
- Depend on wall clock, live network, or unseeded randomness in tests.
- Leave PRs without tests unless the PR includes a clear justification and a follow-up plan.
- Over-mock the unit under test (for example, do not mock the class under test or mock repositories when validating JPA mappings — use `@DataJpaTest` + Testcontainers).

---

## 4. Required Test Types
Use the testing pyramid: many fast unit tests, a reasonable number of slice/integration tests, and a small set of end-to-end tests.

### A. Unit Tests
- Isolated class tests (no Spring context).
- Cover: happy path, at least one edge case, and meaningful branches.
- Use `@ExtendWith(MockitoExtension.class)`. Inject `Clock`/deterministic UUID/Random to guarantee determinism.

**Minimal inline example**
```java
@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {
  @Mock PaymentRepo repo; @InjectMocks PaymentService svc;
  @Test void shouldCreatePayment_whenValid() {
    Clock fixed = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    when(repo.save(any())).thenAnswer(i->i.getArgument(0));
    var p = svc.create(req,fixed);
    assertThat(p.getCreatedAt()).isEqualTo(Instant.parse("2024-01-01T00:00:00Z"));
  }
}
```

### B. Controller / API Slice Tests
- Use `@WebMvcTest` / `MockMvc` or `WebTestClient`.
- Mock service layer with `@MockBean`.
- Cover: success, validation (400), auth (401/403), 404/409.

**Minimal inline example**
```java
@WebMvcTest(UserController.class)
class UserControllerTest {
  @Autowired MockMvc mvc; @MockBean UserService svc;
  @Test void shouldReturnUser_whenFound() throws Exception {
    given(svc.find(1L)).willReturn(new UserDto(1L,"alice"));
    mvc.perform(get("/api/users/1").accept(APPLICATION_JSON))
       .andExpect(status().isOk()).andExpect(jsonPath("$.name").value("alice"));
  }
}
```

### C. Service / Repository Integration Tests
- Use `@DataJpaTest` + Testcontainers.
- Cover CRUD, constraints (unique/FK), transactional rollbacks.
- **MUST** run DB migrations (Flyway/Liquibase) in integration tests when schema is relevant.

**Minimal inline example**
```java
@Testcontainers @DataJpaTest
class UserRepoTest {
  @Container static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:14");
  @DynamicPropertySource static void props(DynamicPropertyRegistry r){
    r.add("spring.datasource.url", pg::getJdbcUrl);
    r.add("spring.datasource.username", pg::getUsername);
    r.add("spring.datasource.password", pg::getPassword);
  }
  @Autowired UserRepository repo;
  @Test void shouldFindActive(){ repo.save(new User(null,"alice",true)); assertThat(repo.findActive()).hasSize(1); }
}
```

### D. End-to-End / Integration Tests
- `@SpringBootTest(webEnvironment=RANDOM_PORT)` + `TestRestTemplate` or `WebTestClient`.
- Cover full happy path, negative flows, auth. Use Testcontainers/WireMock for deps.

### E. Executable mock contracts
- Contracts **MUST** be executable mock servers (WireMock / MockWebServer / Pact) that consumer tests actually hit in CI. API docs alone are **not** acceptable.
- **Executable mock contract:** a versioned, machine-loadable bundle of request→response fixtures (e.g., WireMock `mappings/` + `__files/` or Pact JSON).
- **Purpose:** let consumers run deterministic integration tests (success + error cases) without contacting live providers.
- **AI validation:** When reviewing PRs, AI **SHOULD** validate that mock response fixtures are consistent with the actual provider code (DTOs, serialization logic, field names, types). Flag mismatches between mocked responses and real implementation.

---

## 5. Minimum Coverage per Change
Every change must include tests that exercise the changed behavior. Per-change coverage **MUST** include:
1. Happy path
2. Invalid input or error case
3. Authorization/permission case (if applicable)
4. Edge/boundary case
5. Failure/exception path (if meaningful)

Omit only with an explicit PR justification and a documented follow-up plan.

> **Guideline:** This is behavioral coverage per-change — do not rely on global % coverage as the only gate. If you also track global metrics (e.g., JaCoCo), use them as team signals, not the sole acceptance criterion.

---

## 6. Determinism & Flake Prevention
**MUST**
- **Time:** Inject a `Clock` bean; tests should use `Clock.fixed(...)`.
- **Randomness:** Inject seeded `Random` or a `UuidProvider`.
- **Network:** No outbound HTTP calls in tests — use WireMock/Testcontainers.
- **Async:** Use `Awaitility` or explicit futures with timeouts; avoid `Thread.sleep()`.
- **Secrets:** Do not embed prod credentials. Use CI/secret stores and `application-test.properties.example` for local dev.

---

## 7. Mocking Rules
**Acceptable:** external services, infra (email/analytics), device-like systems.
**Forbidden:** mocking the class under test; mocking repositories when validating JPA mappings (use `@DataJpaTest` + Testcontainers). Avoid mocks that hide broken logic.

---

## 8. Naming & Structure
- Test names: `should<ExpectedOutcome>When<Condition>` or `should <behavior> when <condition>`. Follow repository conventions.
- Use Arrange / Act / Assert.
- One primary assertion reason per test.
- Mirror package structure under `src/test/java`; fixtures under `src/test/resources`.
- Use class suffixes and tags for tooling: `*Test` for unit tests, `*IT` for integration tests, and JUnit `@Tag("integration")` / `@Tag("slow")` where appropriate to let CI run groups.

---

## 9. CODEX PR Review Rules
**Verify** required test types exist (unit/controller/repo/integration).
**Fail** if: uncovered branches, tests using real time/randomness/live network, excessive mocking, snapshot-only behavioral checks, DB/migration changes without DB tests, external contract changes without executable mocks.
**Comment format:** what’s missing, where (file), which rule, and concrete fix suggestion.

---

## 10. Enforcement (CODEX, CI, and Git hooks)
This section explains how rules are enforced and what is automated vs what is left to human reviewers.

### 10.1 Responsibility model
- **Automated (CODEX / CI):** checks that can be run statically or by simple heuristics are enforced automatically by CODEX in PR reviews or by CI jobs. A failure here should block merges where appropriate (e.g., missing migrations tests for schema changes).
- **Flagged for reviewer (human):** judgments that require design knowledge or context (e.g., whether a test meaningfully covers complex business logic or whether over-mocking obscures real behavior) are surfaced as comments for a reviewer to adjudicate. CODEX will provide concrete suggestions and evidence to assist the reviewer.

### 10.2 Examples of checks CODEX/CI SHOULD enforce automatically
These checks are **MUST** automated where possible; false positives are acceptable but must be clear and reversible.
- **Wall-clock usage:** detect `System.currentTimeMillis()`, `Instant.now()`, `ZonedDateTime.now()` in test sources → **FAIL**.
- **Thread.sleep:** detect `Thread.sleep` in tests → **FAIL**.
- **Unseeded randomness:** detect `new Random()` or `UUID.randomUUID()` in tests without an explicit seeded provider → **WARN/FAIL**.
- **Live network calls:** detect HTTP client usage in `src/test` that is not wrapped by WireMock/Testcontainers → **FAIL**.
- **Missing executable mock on external API changes:** if a PR changes external API usage (based on changed endpoints/config), require an executable mock or demonstrate handled in integration tests → **FAIL**.
- **DB changes without migration tests:** PRs that alter schema/migration files **MUST** include migration tests/run migrations in CI → **FAIL**.
- **Slow tests run policy:** tests tagged `@Tag("slow")` or `*IT` should run in an integration test job, not the unit test job.

Implementation note: many of these checks are simple file-pattern/AST/regex checks in CODEX or CI. For more precise detection, CODEX can use lightweight Java parser or grep + heuristics.

### 10.3 What CODEX will flag for a human reviewer
- **Adequacy of behavioral coverage:** whether tests truly cover the new behavior. CODEX should summarize changed code paths and point to missing assertions, but the reviewer must determine sufficiency.
- **Excessive mocking that hides logic:** heuristic flagging is allowed, but human judgement is needed.
- **AI-generated tests review:** PRs containing AI-generated tests **MUST** be marked and require a human reviewer to validate edge cases, naming, and deterministic setup. CODEX will flag presence of generated code and prompt a human reviewer.

### 10.4 Git hooks & local checks
- Provide optional local pre-commit hooks that run a quick subset of the automatable checks (grep for `Thread.sleep`, `Instant.now()` in `src/test`, check for presence of `*IT` -> ensure integration tests aren't in quick test run). These hooks are optional but recommended for fast feedback.

---

## 11. AI Code Generation Requirements
- AI **MUST** add required tests with any code changes.
- AI **MUST** label generated tests (file header or PR description: `Generated-by-AI: yes`) so reviewers can find them.
- Generated tests **MUST** be deterministic, named per conventions, and CI-ready (no `Thread.sleep()`, seeded randomness/time injection).
- AI **SHOULD** prefer slice/integration tests (e.g., controller slice or `@SpringBootTest` with mocks) when unsure which type to add, but **MUST** follow the repository's test structure.
- All AI-generated tests **MUST** be human-reviewed before merge.

---

## 12. Appendix — Examples & Templates
**Appendix A — Quick Examples (copy/paste)**

### Unit test (Clock)
```java
@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {
  @Mock PaymentRepo repo; @InjectMocks PaymentService svc;
  @Test void shouldCreatePayment_whenValid() {
    Clock fixed = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    when(repo.save(any())).thenAnswer(i->i.getArgument(0));
    var p = svc.create(req,fixed);
    assertThat(p.getCreatedAt()).isEqualTo(Instant.parse("2024-01-01T00:00:00Z"));
  }
}
```

### Controller slice (MockMvc)
```java
@WebMvcTest(UserController.class)
class UserControllerTest {
  @Autowired MockMvc mvc; @MockBean UserService svc;
  @Test void shouldReturnUser_whenFound() throws Exception {
    given(svc.find(1L)).willReturn(new UserDto(1L,"alice"));
    mvc.perform(get("/api/users/1").accept(APPLICATION_JSON))
       .andExpect(status().isOk()).andExpect(jsonPath("$.name").value("alice"));
  }
}
```

### Repo integration (Testcontainers)
```java
@Testcontainers @DataJpaTest
class UserRepoTest {
  @Container static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:14");
  @DynamicPropertySource static void props(DynamicPropertyRegistry r){
    r.add("spring.datasource.url", pg::getJdbcUrl);
    r.add("spring.datasource.username", pg::getUsername);
    r.add("spring.datasource.password", pg::getPassword);
  }
  @Autowired UserRepository repo;
  @Test void shouldFindActive(){ repo.save(new User(null,"alice",true)); assertThat(repo.findActive()).hasSize(1); }
}
```

### Integration + WireMock
```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@AutoConfigureWireMock(port=0)
class OrdersIT {
  @Autowired TestRestTemplate rest;
  @Test void shouldPlaceOrder() {
    stubFor(post("/inventory/check").willReturn(aResponse().withStatus(200).withBody("{\"available\":true}")));
    var resp = rest.postForEntity("/api/orders", new OrderRequest(...), OrderResponse.class);
    assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
  }
}
```

### Injecting Clock + UUID provider (recommended pattern)
```java
public interface UuidProvider { UUID randomUuid(); }

@Component
public class DefaultUuidProvider implements UuidProvider { public UUID randomUuid() { return UUID.randomUUID(); } }

@TestConfiguration
public static class TestConfig {
  @Bean public UuidProvider uuidProvider() { return () -> UUID.fromString("00000000-0000-0000-0000-000000000001"); }
}
```

### Awaitility example
```java
await().atMost(Duration.ofSeconds(5))
       .untilAsserted(() -> assertThat(queue.size()).isEqualTo(1));
```

### Maven (Failsafe) snippet for integration tests
```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-failsafe-plugin</artifactId>
  <version>3.0.0-M7</version>
  <configuration>
    <includes>
      <include>**/*IT.java</include>
    </includes>
    <argLine>-Dspring.profiles.active=test</argLine>
  </configuration>
  <executions>
    <execution>
      <goals><goal>integration-test</goal><goal>verify</goal></goals>
    </execution>
  </executions>
</plugin>
```

### Gradle (integrationTest source set)
```groovy
sourceSets {
  integrationTest {
    java.srcDir file('src/integrationTest/java')
    resources.srcDir file('src/integrationTest/resources')
    compileClasspath += sourceSets.main.output + configurations.testRuntimeClasspath
    runtimeClasspath += output + compileClasspath
  }
}
task integrationTest(type: Test) {
  testClassesDirs = sourceSets.integrationTest.output.classesDirs
  classpath = sourceSets.integrationTest.runtimeClasspath
  useJUnitPlatform()
  systemProperty 'spring.profiles.active', 'integration'
}
check.dependsOn integrationTest
```