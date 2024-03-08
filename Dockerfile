FROM maven:3.8.4-openjdk-17 AS build

ARG PORT
ARG DATABASE_URL
ARG DATABASE_USERNAME
ARG DATABASE_PASSWORD

ENV PORT=${PORT}
ENV DATABASE_URL=${DATABASE_URL}
ENV DATABASE_USERNAME=${DATABASE_USERNAME}
ENV DATABASE_PASSWORD=${DATABASE_PASSWORD}

ARG JAR_FILE=*.jar
WORKDIR /build
COPY src src
COPY pom.xml pom.xml

RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package && \
    java -Djarmode=layertools \
    -jar target/${JAR_FILE} \
    extract --destination target/extracted

FROM bellsoft/liberica-openjdk-debian:17
RUN addgroup spring-boot-group && adduser --ingroup spring-boot-group spring-boot
USER spring-boot:spring-boot-group
VOLUME /tmp
WORKDIR /application
COPY --from=build /build/target/extracted/application .
COPY --from=build /build/target/extracted/dependencies .
COPY --from=build /build/target/extracted/snapshot-dependencies .
COPY --from=build /build/target/extracted/spring-boot-loader .
ENTRYPOINT exec java org.springframework.boot.loader.JarLauncher ${0} ${@}