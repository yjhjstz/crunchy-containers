---
title: "Centralized Logging"
date:
draft: false
weight: 70
---

## Centralized Logging Example

The logs generated by containers are critical for deployments because they provide insights into the
health of the system.  PostgreSQL logs are very detailed and there is some information that can only be
obtained from logs (but not limited to):

* Connections and Disconnections of users
* Checkpoint Statistics
* PostgreSQL Server Errors

Aggregrating container logs across multiple hosts allows administrators to audit, debug problems and prevent
repudiation of misconduct.

In the following example we will demonstrate how to setup Kubernetes and OpenShift to use centralized logging by using
an EFK (Elasticsearch, Fluentd and Kibana) stack.  Fluentd will run as a daemonset on each host within the Kubernetes
cluster and extract container logs, Elasticsearch will consume and index the logs gathered by Fluentd and Kibana will allow
users to explore and visualize the logs via a web dashboard.

To learn more about the EFK stack, see the following:

* https://www.elastic.co/products/elasticsearch
* https://www.fluentd.org/architecture
* https://www.elastic.co/products/kibana

## Configure PostgreSQL for Centralized Logging

By default, Crunchy PostgreSQL logs to files in the `/pgdata` directory.  In order to get the logs
out of the container we need to configure PostgreSQL to log to `stdout`.

The following settings should be configured in `postgresql.conf` to make PostgreSQL log to `stdout`:

```
log_destination = 'stderr'
logging_collector = off
```

{{% notice warning %}}
Changes to logging settings require a restart of the PostgreSQL container to take effect.
{{% /notice %}}

## Deploying the EFK Stack On OpenShift Container Platform

OpenShift Container Platform can be installed with an EFK stack.  For more information about
configuring OpenShift to create an EFK stack, see the official documentation:

* https://docs.openshift.com/container-platform/3.11/install_config/aggregate_logging.html

## Deploying the EFK Stack On Kubernetes

First, deploy the EFK stack by running the example using the following commands:

```
cd $CCPROOT/examples/kube/centralized-logging/efk
./run.sh
```

{{% notice warning %}}
Elasticsearch is configured to use an `emptyDir` volume in this example.  Configure this example to provide a
persistent volume when deploying into production.
{{% /notice %}}


Next, verify the pods are running in the `kube-system` namespace:

```
${CCP_CLI?} get pods -n kube-system --selector=k8s-app=elasticsearch-logging
${CCP_CLI?} get pods -n kube-system --selector=k8s-app=fluentd-es
${CCP_CLI?} get pods -n kube-system --selector=k8s-app=kibana-logging
```

If all pods deployed successfully, Elasticsearch should already be receiving container logs from Fluentd.

Next we will deploy a PostgreSQL Cluster (primary and replica deployments) to demonstrate PostgreSQL logs
are being captured by Fluentd.

Deploy the PostgreSQL cluster by running the following:

```
cd $CCPROOT/examples/kube/centralized-logging/postgres-cluster
./run.sh
```

Next, verify the pods are running:

```
${CCP_CLI?} get pods --selector=k8s-app=postgres-cluster
```

With the PostgreSQL successfully deployed, we can now query the logs in Kibana.

We will need to setup a port-forward to the Kibana pod to access it.  To do that
we first get the name of the pod by running the following command:

```
${CCP_CLI?} get pod --selector=k8s-app=kibana-logging -n kube-system
```

Next, start the port-forward:

```
${CCP_CLI?} port-forward <KIBANA POD NAME> 5601:5601 -n kube-system
```

To access the web dashboard navigate in a browser to `127.0.0.1:5601`.

First, click the `Discover` tab and setup an index pattern to use for queries.

The index pattern name we will use is `logstash-*` because Fluentd is configured to
generate logstash style logs.

Next we will configure the `Time Filter field name` to be `@timestamp`.

Now that our index pattern is created, we can query for the container logs.

Click the `Discover` tab and use the following queries:

```
# KUBERNETES
CONTAINER_NAME: *primary* AND MESSAGE: ".*LOG*"
# OpenShift
kubernetes.pod_name: "primary" AND log
```

For more information about querying Kibana, see the official documentation: https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html

To delete the centralized logging example run the following:

```
${CCP_ROOT?}/examples/kube/centralized-logging/efk/cleanup.sh
```

To delete the cluster roles required by the EFK stack, as an administrator, run the following:

```
${CCP_ROOT?}/examples/kube/centralized-logging/efk/cleanup-rbac.sh
```
