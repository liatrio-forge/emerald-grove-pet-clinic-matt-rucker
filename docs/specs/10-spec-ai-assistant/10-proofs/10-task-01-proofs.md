# Task 1.0 Proof Artifacts — Spring AI Foundation and Configuration

## CLI Output: `./mvnw compile`

```
[INFO] BUILD SUCCESS
```

Spring AI 2.0.0-M4 dependencies resolved from Spring Milestones repository. Application compiles with `spring-ai-starter-model-anthropic` on the classpath.

## Configuration Added

### pom.xml changes

- Added `<spring-ai.version>2.0.0-M4</spring-ai.version>` property
- Added `<dependencyManagement>` with Spring AI BOM import
- Added `spring-ai-starter-model-anthropic` dependency
- Added Spring Milestones repository (`https://repo.spring.io/milestone`)

### application.properties additions

```properties
# Spring AI - Anthropic
spring.ai.anthropic.api-key=${ANTHROPIC_API_KEY:}
spring.ai.anthropic.chat.options.model=claude-sonnet-4-20250514
spring.ai.anthropic.chat.options.max-tokens=1024
```

API key reads from `ANTHROPIC_API_KEY` environment variable with empty default (app starts without it).

## Verification

- `./mvnw compile` → BUILD SUCCESS
- `./mvnw spring-javaformat:apply` → no formatting issues
