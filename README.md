# Changes made to the original `storm` image

* Removed support for Apache Storm versions 1.0.x and 1.1.x
* Replaced base image `openjdk:8-jre-alpine` with `openjdk:11`
* `openjdk:11` is Debian based, `apk add` needed to be replaced with `apt-get install`
* Installed some extra certificates
* Enabled profiling and reconfigured JVM debugging options for OpenJDK 11 in `storm.yaml`
* Provided workaround for https://bugs.debian.org/910804
* Added [Storm metrics reporter for Prometheus Gateway](https://github.com/wizenoze/storm-metrics-reporter-prometheus)
* Added [Sentry](https://docs.sentry.io/clients/java/) support

# Supported tags and respective `Dockerfile` links

* `1.2.2`, `1.2`, `latest` [(1.2.2/Dockerfile)](https://github.com/wizenoze/storm-docker/blob/master/1.2.2/Dockerfile)

[![](https://images.microbadger.com/badges/image/wizenoze/storm.svg)](http://microbadger.com/images/wizenoze/storm)

# What is Apache Storm?

Apache Storm is a distributed computation framework written predominantly in the Clojure programming language. Originally created by Nathan Marz and team at BackType, the project was open sourced after being acquired by Twitter. It uses custom created "spouts" and "bolts" to define information sources and manipulations to allow batch, distributed processing of streaming data. The initial release was on 17 September 2011.

> [wikipedia.org/wiki/Storm_(event_processor)](https://en.wikipedia.org/wiki/Storm_(event_processor))

![](https://upload.wikimedia.org/wikipedia/commons/7/70/Storm_logo.png)

# How to use this image

## Running topologies in local mode

Assuming you have `topology.jar` in the current directory.

	$ docker run -it -v $(pwd)/topology.jar:/topology.jar wizenoze/storm storm jar /topology.jar org.apache.storm.starter.ExclamationTopology

## Setting up a minimal Storm cluster

1.	[Apache Zookeeper](https://zookeeper.apache.org/) is a must for running a Storm cluster. Start it first. Since the Zookeeper "fails fast" it's better to always restart it.

		$ docker run -d --restart always --name some-zookeeper zookeeper

2.	The Nimbus daemon has to be connected with the Zookeeper. It's also a "fail fast" system.

		$ docker run -d --restart always --name some-nimbus --link some-zookeeper:zookeeper wizenoze/storm storm nimbus

3.	Finally start a single Supervisor node. It will talk to the Nimbus and Zookeeper.

		$ docker run -d --restart always --name supervisor --link some-zookeeper:zookeeper --link some-nimbus:nimbus wizenoze/storm storm supervisor

4.	Now you can submit a topology to our cluster.

		$ docker run --link some-nimbus:nimbus -it --rm -v $(pwd)/topology.jar:/topology.jar wizenoze/storm storm jar /topology.jar org.apache.storm.starter.WordCountTopology topology

5.	Optionally, you can start the Storm UI.

		$ docker run -d -p 8080:8080 --restart always --name ui --link some-nimbus:nimbus wizenoze/storm storm ui

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `stack.yml` for `wizenoze/storm`:

```yaml
version: '3.1'

services:
    zookeeper:
        image: zookeeper
        container_name: zookeeper
        # https://github.com/31z4/zookeeper-docker/#how-to-configure-logging
        environment:
            - ZOO_LOG4J_PROP=INFO,ROLLINGFILE
        restart: always

    storm-nimbus:
        image: wizenoze/storm:1.2.2
        container_name: storm-nimbus
        command: storm nimbus
        depends_on:
            - zookeeper
        links:
            - zookeeper
        ports:
            - 6627:6627
        restart: always

    storm-ui:
        image: wizenoze/storm:1.2.2
        container_name: storm-ui
        command: storm ui
        depends_on:
            - storm-nimbus
            - zookeeper
        links:
            - storm-nimbus
            - zookeeper
        ports:
            - 9080:8080
        restart: always

    storm-worker:
        image: wizenoze/storm:1.2.2
        container_name: storm-worker
        command: storm supervisor
        depends_on:
            - storm-nimbus
            - zookeeper
        links:
            - storm-nimbus
            - zookeeper
        restart: always
```

Run `docker stack deploy -c stack.yml storm` (or `docker-compose -f stack.yml up`) and wait for it to initialize completely. The Nimbus will be available at `http://swarm-ip:6627`, `http://localhost:6627`, or `http://host-ip:6627` (as appropriate).

## Configuration

This image uses [default configuration](https://github.com/apache/storm/blob/v1.1.1/conf/defaults.yaml) of the Apache Storm. There are two main ways to change it.

1.	Using command line arguments.

		$ docker run -d --restart always --name nimbus wizenoze/storm storm nimbus -c storm.zookeeper.servers='["zookeeper"]'

2.	Assuming you have `storm.yaml` in the current directory you can mount it as a volume.

		$ docker run -it -v $(pwd)/storm.yaml:/conf/storm.yaml wizenoze/storm storm nimbus

## Logging

This image uses [default logging configuration](https://github.com/apache/storm/tree/v1.1.1/log4j2). All logs go to the `/logs` directory by default.

## Data persistence

No data are persisted by default. For convenience there are `/data` and `/logs` directories in the image owned by `storm` user. Use them accordingly to persist data and logs using volumes.

	$ docker run -it -v /logs -v /data wizenoze/storm storm nimbus

*Please be noticed that using paths other than those predefined is likely to cause permission denied errors. It's because for [security reasons](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#user) the Storm is running under the non-root `storm` user.*

# License

View [license information](http://storm.apache.org/about/free-and-open-source.html) for the software contained in this image.
