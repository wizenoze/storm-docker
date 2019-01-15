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
        gnupg \
        gosu \
        less && \
    rm -rf /var/lib/apt/lists/*

# Install additional certificates
COPY extra-certs /usr/local/share/ca-certificates
RUN update-ca-certificates

ENV STORM_USER=storm \
    STORM_CONF_DIR=/conf \
    STORM_DATA_DIR=/data \
    STORM_LOG_DIR=/logs

# Add a user and make dirs
RUN set -ex; \
    useradd --system "$STORM_USER"; \
    mkdir -p "$STORM_CONF_DIR" "$STORM_DATA_DIR" "$STORM_LOG_DIR"; \
    chown -R "$STORM_USER:$STORM_USER" "$STORM_CONF_DIR" "$STORM_DATA_DIR" "$STORM_LOG_DIR"``

ARG STORM_GPG_KEY=ACEFE18DD2322E1E84587A148DE03962E80B8FFD
ARG STORM_DISTRO_NAME=apache-storm-1.2.2

# Download Apache Storm, verify its PGP signature, untar and clean up
RUN set -ex; \
    wget -q "http://www.apache.org/dist/storm/$STORM_DISTRO_NAME/$STORM_DISTRO_NAME.tar.gz"; \
    wget -q "http://www.apache.org/dist/storm/$STORM_DISTRO_NAME/$STORM_DISTRO_NAME.tar.gz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$STORM_GPG_KEY" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$STORM_GPG_KEY" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$STORM_GPG_KEY"; \
    gpg --batch --verify "$STORM_DISTRO_NAME.tar.gz.asc" "$STORM_DISTRO_NAME.tar.gz"; \
    tar -xzf "$STORM_DISTRO_NAME.tar.gz"; \
    chown -R "$STORM_USER:$STORM_USER" "$STORM_DISTRO_NAME"; \
    rm -rf "$GNUPGHOME" "$STORM_DISTRO_NAME.tar.gz" "$STORM_DISTRO_NAME.tar.gz.asc";

WORKDIR $STORM_DISTRO_NAME

ENV PATH $PATH:/$STORM_DISTRO_NAME/bin

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
