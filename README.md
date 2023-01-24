# Demonstrate OpenShift Pipelines with Spring Boot Hello-World

This app is for demoing OpenShift Pipelines

## Prerequisites

This demonstration requires the following resources:
- [OpenShift Container Platform 4.12.x](https://www.redhat.com/en/technologies/cloud-computing/openshift/try-it)
- GitHub account with [hello-world](https://github.com/rseip-rh/hello-world) and [hello-world-deploy](https://github.com/rseip-rh/hello-world-deploy) projects
- [quay.io](https://quay.io/user/rseip/) container registry account

### Install OpenShift Pipelines Operator

Login as kubeadmin to console-openshift-console . Navigate to Operators -> OperatorHub. Filter by "Red Hat OpenShift Pipelines". Click the operator. Click "Install". Accept default values. Click "Install".

### Install OpenShift GitOps Operator

Login as kubeadmin to console-openshift-console . Navigate to Operators -> OperatorHub. Filter by "Red Hat OpenShift GitOps". Click the operator. Click "Install". Accept default values. Click "Install".

### Enable monitoring for user-defined projects

Apply the [YAML](Monitoring/cluster-monitoring-config.yaml) from the Monitoring folder.

`oc project hello-world`
`oc apply -f Monitoring/cluster-monitoring-config.yaml`

Refer to [Enabling monitoring for user-defined projects](https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html) for details.

## Setup and configure ArgoCD

### Setup the namespaces and give permissions to ArgoCD Service Account

```
oc create ns hello-world
oc create ns hello-world-dev
oc create ns hello-world-pipeline
#oc label namespace hello-world argocd.argoproj.io/managed-by=openshift-gitops
oc policy add-role-to-user monitoring-edit system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n hello-world
#oc label namespace hello-world-dev argocd.argoproj.io/managed-by=openshift-gitops
oc policy add-role-to-user monitoring-edit system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n hello-world-dev
```

### Add applications to ArgoCD

Apply the YAML from the [argo](argo/) folder. Note that `namespace` value depends on which ArgoCD is being used (OpenShift GitOps Operator or Big Bang helm); modify as appropriate. For OpenShift GitOps Operator, the value is `openshift-gitops`. For Big Bang, the value is `argocd`.

If repo is available locally:

```
oc apply -f argo/app-dev.yaml
oc apply -f argo/app.yaml
oc apply -f argo/tekton.yaml
```

Otherwise, copy each file contents and paste/import via the OpenShift console.

### Validate ArgoCD user interface

#### OpenShift GitOps Operator
Login to OpenShift console. Navigate to Networking -> Routes. Change Project to `openshift-gitops`, be sure to enable "Show default projects". Click the Location link for the `openshift-gitops-server` route. A new browser window appears. Confirm authorization. Confirm that "Applications" shows `dev-hello-world`, `hello-world-tekton`, and `prod-hello-world`.

#### Big Bang ArgoCD Helm install
Navigate to `argocd.bigbang.dev`. Login as `admin`. Default password can be found as:

```
oc -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Confirm that "Applications" shows `dev-hello-world`, `hello-world-tekton`, and `prod-hello-world`.

## Set up demo pipelines

### Setup Tekton Task github-set-status

Make sure to run from inside namespace hello-world-pipeline

`oc project hello-world-pipeline`

If GitHub token has not yet been created:

Get token from GitHub. Settings -> Developer Settings -> Personal access tokens -> Tokens (classic) -> Generate new token -> Generate new token (classic). Grant "repo" permissions. Take note of lifetime expiration.

Proceed with creating the secret.

```
oc create secret generic github --from-literal token="MY_TOKEN"
oc get secret github
oc describe secret github
```

### Use basic-auth credentials for git-cli task

[https://hub.tekton.dev/tekton/task/git-cli](https://hub.tekton.dev/tekton/task/git-cli)

Replace `<user>` and `<pass>` with your values.

```
kind: Secret
apiVersion: v1
metadata:
  name: github-basic-auth-secret
type: Opaque
stringData:
  .gitconfig: |
    [credential "https://github.com"]
      helper = store
  .git-credentials: |
    https://<user>:<pass>@github.com
```

### Add secret for access to quay

Replace <username> and <password> with values from quay.io. The password should be the encrypted CLI format.

```
oc project hello-world
oc create secret docker-registry quay-registry --docker-server=quay.io --docker-username=<username> --docker-password=<password>
oc secrets link default quay-registry --for=pull,mount
oc secrets link pipeline quay-registry --for=pull,mount
```

```
oc project hello-world-dev
oc create secret docker-registry quay-registry --docker-server=quay.io --docker-username=<username> --docker-password=<password>
oc secrets link default quay-registry --for=pull,mount
oc secrets link pipeline quay-registry --for=pull,mount
```

### Point Webhook at triggers

```
oc project hello-world
oc get routes
```

In GitHub navigate to Settings -> webhooks -> add webhook.

For `el-hello-world-app`, use the `HOST/PORT` value to create a push webhook. Ensure payload URL is prefixed with `http://` and a trailing slash `/`. Change the content type to `application/json`.

For `el-hello-world-test-app`, use the `HOST/PORT` value to create a push webhook. Ensure payload URL is prefixed with `http://` and a trailing slash `/`. Change the content type to `application/json`. Enable ONLY pull request events.

TODO - explore use of CLI to create these webhooks
  


Import via the OpenShift console.

### Allow pipeline service account to read the cluster api

`oc adm policy add-cluster-role-to-user cluster-reader -z pipeline`

--- CURRENT PROGRESS ---

### Set up Prometheus Monitoring

Apply the manifest in Monitoring

`oc adm policy add-cluster-role-to-user monitoring-edit -z pipeline`

### Set up custom Grafana dashboards

Refer to blog post [Custom Grafana dashboards for Red Hat OpenShift Container Platform 4](https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4).

#### Add Grafana Operator to namespace my-grafana

#### Create a Grafana instance with the name my-grafana

`oc apply -f Grafana/grafana.yaml`

`oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount`

`oc serviceaccounts get-token grafana-serviceaccount -n my-grafana`

#### Replace BEARER_TOKEN in grafana-ds.yaml

`oc apply -f Grafana/grafana-ds.yaml`
