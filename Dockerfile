#FROM registry1.dso.mil/ironbank/redhat/openjdk/openjdk8:1.8.0
FROM registry1.dso.mil/ironbank/redhat/openjdk/openjdk8-slim:1.8.0
#FROM registry.access.redhat.com/ubi8/openjdk-8-runtime:1.14
#FROM openjdk:8-jre-alpine

ENV APP_JAR_NAME hello-world

ENV APP_HOME /opt/${APP_JAR_NAME}
ENV APP_JAR ${APP_JAR_NAME}.jar

USER root

COPY target/*.jar ${APP_HOME}/${APP_JAR}
COPY docker-entrypoint.sh /docker-entrypoint.sh

#RUN apk upgrade --update && apk add su-exec && \
# RUN microdnf update && \ 
RUN sh -c 'touch ${APP_HOME}/${APP_JAR}' && \
    chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8080 9090
