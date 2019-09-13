FROM openjdk:11

# Workaround for https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=910804
RUN mkdir -p $JAVA_HOME/lib/jfr && \
    wget https://hg.openjdk.java.net/jdk/jdk11/raw-file/76072a077ee1/src/jdk.jfr/share/conf/jfr/default.jfc \
      -O $JAVA_HOME/lib/jfr/default.jfc && \
    wget https://hg.openjdk.java.net/jdk/jdk11/raw-file/76072a077ee1/src/jdk.jfr/share/conf/jfr/profile.jfc \
      -O $JAVA_HOME/lib/jfr/profile.jfc

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python-minimal \
        ca-certificates \
        gosu \
        less && \
    rm -rf /var/lib/apt/lists/*

# Install additional certificates
COPY extra-certs /usr/local/share/ca-certificates
RUN update-ca-certificates

ENV STORM_USER=storm \
    STORM_CONF_DIR=/conf \
    STORM_DATA_DIR=/data \
    STORM_LOG_DIR=/logs \
    PROMETHEUS_SCHEME=http \
    PROMETHEUS_PORT=9091 \
    PROMETHEUS_REPORT_PERIOD_MIN=10 \
    SENTRY_VERSION="1.7.17" \
    # Sentry depends on Jackson, you can customize its version here
    JACKSON_VERSION="2.9.8" \
    # Set DSN (Data Source Name) to enable error reporting to Sentry
    # https://docs.sentry.io/clients/java/#setting-the-dsn
    SENTRY_DSN="" \
    # Configure in-app stack frames
    # https://docs.sentry.io/clients/java/config/#in-application-stack-frames
    SENTRY_APP_PACKAGES=""

# Add a user and make dirs
RUN set -ex; \
    useradd --system "$STORM_USER"; \
    mkdir -p "$STORM_CONF_DIR" "$STORM_DATA_DIR" "$STORM_LOG_DIR"; \
    chown -R "$STORM_USER:$STORM_USER" "$STORM_CONF_DIR" "$STORM_DATA_DIR" "$STORM_LOG_DIR"``

ARG STORM_GPG_KEY=ACEFE18DD2322E1E84587A148DE03962E80B8FFD
ARG STORM_DISTRO_NAME=apache-storm-1.2.2

# Download Apache Storm, verify its PGP signature, untar and clean up
RUN set -ex; \
    wget -q "http://archive.apache.org/dist/storm/$STORM_DISTRO_NAME/$STORM_DISTRO_NAME.tar.gz"; \
    tar -xzf "$STORM_DISTRO_NAME.tar.gz"; \
    chown -R "$STORM_USER:$STORM_USER" "$STORM_DISTRO_NAME"; \
    rm -f "$STORM_DISTRO_NAME.tar.gz";

WORKDIR $STORM_DISTRO_NAME

ARG STORM_METRICS_REPORTER_PROMETHEUS_GPG_KEY=C73B4AB37E0AF60909385973EE6C2B91726E4F8D
ARG STORM_METRICS_REPORTER_VERSION=0.0.1
ARG STORM_METRICS_REPORTER_JAR=storm-metrics-reporter-prometheus-$STORM_METRICS_REPORTER_VERSION.jar

# Download Apache Storm, verify its PGP signature, untar and clean up
RUN set -ex; \
    wget -q "https://github.com/wizenoze/storm-metrics-reporter-prometheus/releases/download/$STORM_METRICS_REPORTER_VERSION/$STORM_METRICS_REPORTER_JAR"; \
    chown -R "$STORM_USER:$STORM_USER" "$STORM_METRICS_REPORTER_JAR"; \
    cp "$STORM_METRICS_REPORTER_JAR" extlib; \
    cp "$STORM_METRICS_REPORTER_JAR" extlib-daemon; \
    rm -f "$STORM_METRICS_REPORTER_JAR";

# Used by Sentry when enabled through SENTRY_DSN
COPY worker.xml /conf

ENV PATH $PATH:/$STORM_DISTRO_NAME/bin

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
