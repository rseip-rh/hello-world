# Spring Boot Hello-World application
This app is for demoing OpenShift Pipelines

# Prerequisites

## Add Pipelines Operator

## Add GitOps Operator

## Turn on User Monitoring

Apply the [yaml](Monitoring/cluster-monitoring-config.yaml) in the monitoring folder

Refer to [Enabling monitoring for user-defined projects](https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html) for details.

# Setup using ArgoCD

## Setup the namespace and give permissions to ArgoCD Service Account

```
oc create ns hello-world
oc label namespace hello-world argocd.argoproj.io/managed-by=openshift-gitops
oc policy add-role-to-user monitoring-edit system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n hello-world
oc create ns hello-world-dev
oc label namespace hello-world-dev argocd.argoproj.io/managed-by=openshift-gitops
oc policy add-role-to-user monitoring-edit system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n hello-world-dev
```


## Add ArgoCD Applications

Add the yamls in the argo folder

- GUI login
- networking
- openshift-gitops ns
- route, click and open in new window
- confirm authorization
- pvc's are spinning until pipeline is run

# Demo Setup

## Setup Tekton Task github-set-status

Make sure to run from inside namespace hello-world

`oc project hello-world`

Get token from GitHub. Settings -> Developer Settings -> Personal access tokens -> Tokens (classic) -> Generate new token -> Generate new token (classic). Grant "repo" permissions. Take note of lifetime expiration.

`oc create secret generic github --from-literal token="MY_TOKEN" `

`oc get secret github`

`oc describe secret github`

## Add secret for access to quay

`oc create secret docker-registry quay-registry --docker-server=quay.io --docker-username=<username> --docker-password=<password>`

`oc secrets link pipeline quay-registry --for=pull,mount`

## Add Triggers and Tasks

## Point Webhook at triggers

`oc get routes`

## Allow pipeline service account to read the cluster api

`oc adm policy add-cluster-role-to-user cluster-reader -z pipeline`

## Setup for Prometheus Monitoring

Apply the manifest in Monitoring

`oc adm policy add-cluster-role-to-user monitoring-edit -z pipeline`

## Setup User defined Grafana

https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4

### Add Grafana Operator to namespace my-grafana

### Create a Grafana instance with the name my-grafana

`oc apply -f Grafana/grafana.yaml`

`oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount`

`oc serviceaccounts get-token grafana-serviceaccount -n my-grafana`

### Replace BEARER_TOKEN in grafana-ds.yaml

`oc apply -f Grafana/grafana-ds.yaml`
