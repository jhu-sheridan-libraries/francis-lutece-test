# syntax=docker/dockerfile:1

arg LUTECE_INIT_TAG=0.8

FROM maven:3.6.3-openjdk-8 as builder

RUN mkdir -p /data /build
WORKDIR /build
COPY pom.xml .
COPY src ./src
COPY webapp ./webapp
WORKDIR /tmp
RUN git clone https://github.com/jhu-sheridan-libraries/lutece-enroll-plugin.git && \
    cd lutece-enroll-plugin && \
    mvn install -Dmaven.test.skip

WORKDIR /tmp
RUN git clone https://github.com/jhu-sheridan-libraries/gru-plugin-appointment.git && \
    cd gru-plugin-appointment && \
    git checkout i18n-2.2 && \
    mvn install -Dmaven.test.skip

WORKDIR /build
RUN mvn lutece:site-assembly

RUN cp /build/target/stfrancis-*.war /lutece.war
WORKDIR /

FROM ghcr.io/jhu-sheridan-libraries/lutece-init:$LUTECE_INIT_TAG
RUN mkdir -p /data
COPY --from=builder /lutece.war /data/lutece.war
