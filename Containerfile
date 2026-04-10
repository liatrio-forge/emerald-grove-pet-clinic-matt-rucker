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

# Extract application for optimized runtime layout
# Spring Boot 4 extract produces: app.jar (thin) + lib/ (dependencies)
RUN java -Djarmode=tools -jar target/*.jar extract --destination /workspace/extracted

# Stage 2: Runtime (distroless)
FROM cgr.dev/chainguard/jre:latest AS runtime

WORKDIR /app

# Copy dependencies first (changes rarely — cached layer)
COPY --from=build /workspace/extracted/lib/ ./lib/

# Copy application JAR (changes frequently)
COPY --from=build /workspace/extracted/*.jar ./application.jar

# Runtime configuration
ENV SPRING_PROFILES_ACTIVE=postgres
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]
