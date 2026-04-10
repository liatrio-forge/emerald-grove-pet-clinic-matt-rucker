# Stage 1: Build
FROM docker.io/library/maven:3.9-amazoncorretto-17 AS build

WORKDIR /workspace

# Copy Maven wrapper and build definition first (cached layer)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline -B

# Copy source and build
COPY src/ src/
RUN ./mvnw package -DskipTests -B

# Extract layered JAR
RUN java -Djarmode=tools -jar target/*.jar extract --layers --destination /workspace/extracted

# Stage 2: Runtime (distroless)
FROM cgr.dev/chainguard/jre:latest AS runtime

WORKDIR /app

# Copy layers in dependency order for optimal caching
COPY --from=build /workspace/extracted/dependencies/ ./
COPY --from=build /workspace/extracted/spring-boot-loader/ ./
COPY --from=build /workspace/extracted/snapshot-dependencies/ ./
COPY --from=build /workspace/extracted/application/ ./

# Runtime configuration
ENV SPRING_PROFILES_ACTIVE=postgres
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"

EXPOSE 8080

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
