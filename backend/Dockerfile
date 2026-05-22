FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

EXPOSE 8080

COPY build/extracted/dependencies/ ./
COPY build/extracted/spring-boot-loader/ ./
COPY build/extracted/snapshot-dependencies/ ./
COPY build/extracted/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]