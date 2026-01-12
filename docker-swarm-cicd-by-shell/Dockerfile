# Simple Dockerfile - expects pre-built JAR
# Java 25 with ZGC (Generational Z Garbage Collector)
FROM eclipse-temurin:25-jre

ARG APP_JAR
ENV APP_JAR_ENV=${APP_JAR}
ENV SPRING_PROFILES_ACTIVE=uat
WORKDIR /app


# Add non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

RUN echo "jar name is" ${APP_JAR_ENV}

# Copy the pre-built jar (build with: ./gradlew :adapter-mng:bootJar)
COPY ${APP_JAR} ${APP_JAR}

# Set ownership
RUN chown -R spring:spring /app

USER spring

#-Dspring.context.exit=onRefresh：這是關鍵！它讓 Spring Boot 在 Bean 初始化完成後立刻退出，避免連接資料庫或開啟伺服器埠口，快速完成訓練。

RUN java -XX:ArchiveClassesAtExit=app-cds.jsa \
    -Dspring.context.exit=onRefresh \
    -Dspring.aot.enabled=true \
    -jar ${APP_JAR_ENV} || true

# JVM options for container environment with ZGC
# ZGC: Low-latency garbage collector with sub-millisecond pause times
ENV JAVA_OPTS="-XX:+UseZGC \
    -XX:+ZGenerational \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0"
ENV APP_JAR=${APP_JAR}
EXPOSE 18080
