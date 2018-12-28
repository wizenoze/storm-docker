#!/bin/bash

set -e

# Allow the container to be started with `--user`
if [ "$1" = 'storm' -a "$(id -u)" = '0' ]; then
    chown -R "$STORM_USER" "$STORM_CONF_DIR" "$STORM_DATA_DIR" "$STORM_LOG_DIR"
    exec gosu "$STORM_USER" "$0" "$@"
fi

# Generate the config only if it doesn't exist
# https://issues.apache.org/jira/browse/STORM-320
CONFIG="$STORM_CONF_DIR/storm.yaml"
if [ ! -f "$CONFIG" ]; then
    cat << EOF > "$CONFIG"
#how many seconds to sleep for before shutting down threads on worker (default: 3)
supervisor.worker.shutdown.sleep.secs: 10

#how frequently the supervisor checks on the status of the processes it's monitoring and restarts if necessary (default: 3)
supervisor.monitor.frequency.secs: 5

storm.zookeeper.servers: [zookeeper]
nimbus.seeds: [storm-nimbus]
storm.log.dir: "$STORM_LOG_DIR"
storm.local.dir: "$STORM_DATA_DIR"

worker.profiler.enabled: true

# Leverage unified logging for debugging the GC, old options aren't valid any more
# See: http://openjdk.java.net/jeps/271
worker.childopts: "-Xmx%HEAP-MEM%m -Xlog:gc*=debug:file=artifacts/gc.log:utctime,uptime,tid,level:filecount=10,filesize=128m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=artifacts/heapdump.hprof"

# Customize JFR options, -XX:+UnlockCommercialFeatures gives an error on OpenJDK 11
# See: https://docs.oracle.com/en/java/javase/11/tools/java.html#GUID-3B1CE181-CD30-4178-9602-230B800D4FAE
worker.profiler.childopts: "-XX:StartFlightRecording=disk=true,dumponexit=true,filename=artifacts/recording.jfr,maxsize=1024m,maxage=1d,settings=default"
EOF
fi

exec "$@"
