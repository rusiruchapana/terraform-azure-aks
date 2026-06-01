# Beginner Lab 03 - Deploy Image from a Container Registry

This lab shows how to deploy a container image from a container registry to AKS.

This is a standalone beginner lab.

The default manifest uses a public NGINX image so the first run is simple.

You can also change the image to use:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- Another private registry

## Lab goal

By the end of this lab, you should have:

- A Kubernetes namespace named `beginner-registry`
- A Deployment named `registry-demo`
- A Service named `registry-demo`
- One running pod created from a registry image
- The application accessible from your laptop using `kubectl port-forward`

The local test URL is:

    http://localhost:8081

## What you will learn

You will learn:

- How Kubernetes references container images
- How to deploy an image from a registry
- How public and private registries differ
- How AKS pulls images from Azure Container Registry
- When `imagePullSecret` is required
- How to troubleshoot `ImagePullBackOff`
- How to verify image tags in ACR
- How to clean up lab resources safely

## Lab architecture

The default flow is:

    AKS cluster
      |
      v
    Namespace: beginner-registry
      |
      v
    Deployment: registry-demo
      |
      v
    Image: nginx:1.27-alpine
      |
      v
    Pod: registry-demo
      |
      v
    Service: registry-demo
      |
      v
    kubectl port-forward
      |
      v
    http://localhost:8081

If you use ACR, the flow is:

    AKS kubelet identity
      |
      | AcrPull permission
      v
    Azure Container Registry
      |
      v
    Container image

If you use a private external registry, the flow usually needs:

    Kubernetes imagePullSecret
      |
      v
    Private registry credentials

## What this lab requires

You need:

- kubectl
- Access to an AKS cluster
- A terminal
- A web browser

For the default public image path, you do not need:

- Docker Desktop
- Azure Container Registry
- Registry credentials

For an ACR image, you need:

- Existing ACR
- Image already pushed to ACR
- AKS permission to pull from ACR

For a private external registry, you need:

- Registry server name
- Registry username or token
- Registry password or token
- Kubernetes imagePullSecret

## Install required local tools

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

### Azure CLI for ACR option

Azure CLI is only needed if you test the ACR option.

Install Azure CLI:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Verify Azure CLI:

    az version

## Check local tools and AKS access

Before continuing, verify that kubectl can reach your AKS cluster:

    kubectl get nodes

Expected:

    Nodes should show Ready status.

If you use ACR, verify Azure access:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

## Files in this lab

This lab includes:

    manifests/
      Kubernetes manifests for namespace, deployment, and service

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml

The default image is:

    nginx:1.27-alpine

The Deployment also includes a commented `imagePullSecrets` example for private external registries.

## Important node selector note

The Deployment includes this node selector:

    nodeSelector:
      workload: user

This means the pod will schedule only on nodes that have this label:

    workload=user

Check whether your nodes have that label:

    kubectl get nodes --show-labels | grep "workload=user" || true

If your cluster does not use this label, either add the label to a worker node or remove the `nodeSelector` from the manifest.

To label a node for this lab:

    kubectl get nodes

Then choose a node name and run:

    kubectl label node <node-name> workload=user --overwrite

## Registry options

### Option A - Public image

This is the simplest option.

The default manifest already uses:

    image: nginx:1.27-alpine

Public images usually do not need `imagePullSecret`.

### Option B - Azure Container Registry

Use this option if your image is stored in ACR.

Image format:

    <acr-login-server>/<repository>:<tag>

Example:

    myacr.azurecr.io/demo-web:v1

List ACR registries:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

List repositories:

    az acr repository list \
      --name <acr-name> \
      --output table

List image tags:

    az acr repository show-tags \
      --name <acr-name> \
      --repository <repository-name> \
      --output table

Check whether AKS can pull from ACR:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

If needed, attach ACR to AKS:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

If ACR pull permission is configured correctly, AKS can pull from ACR without an `imagePullSecret`.

### Option C - Private external registry

Use this option if your image is in a private registry outside ACR.

Private external registries usually require an `imagePullSecret`.

Create the secret in the same namespace as the Deployment:

    kubectl create secret docker-registry registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password-or-token> \
      --docker-email=<email> \
      -n beginner-registry

Then uncomment this section in `manifests/deployment.yaml`:

    imagePullSecrets:
      - name: registry-secret

The secret must exist in:

    beginner-registry

## Before you deploy

Open this file:

    labs/beginner/03-registry-image/manifests/deployment.yaml

For the first test, you can keep:

    image: nginx:1.27-alpine

To test your own registry image, replace the image value.

Examples:

    image: myacr.azurecr.io/demo-web:v1
    image: docker.io/myuser/demo-web:v1
    image: ghcr.io/myorg/demo-web:v1

If you use a private external registry, create the `registry-secret` first and uncomment `imagePullSecrets`.

## Deploy the lab

Run these commands from the repository root.

Apply the namespace first:

    kubectl apply -f labs/beginner/03-registry-image/manifests/namespace.yaml

If you are using a private external registry, create the image pull secret now.

Apply the app resources:

    kubectl apply -f labs/beginner/03-registry-image/manifests/deployment.yaml
    kubectl apply -f labs/beginner/03-registry-image/manifests/service.yaml

## Verify resources

Check the namespace:

    kubectl get namespace beginner-registry

Check pods:

    kubectl get pods -n beginner-registry -o wide

Check rollout:

    kubectl rollout status deployment/registry-demo -n beginner-registry --timeout=180s

Check the Service:

    kubectl get svc registry-demo -n beginner-registry

Expected:

    namespace exists
    pod status is Running
    deployment rollout is successful
    service type is ClusterIP

## Access the app locally

Use port-forward:

    kubectl port-forward svc/registry-demo -n beginner-registry 8081:80

Open this URL in your browser:

    http://localhost:8081

If you kept the default NGINX image, you should see the default NGINX welcome page.

You can also test with curl from another terminal:

    curl http://localhost:8081

Stop the port-forward with:

    Ctrl+C

## Troubleshooting

### ImagePullBackOff

Check pods:

    kubectl get pods -n beginner-registry

Describe the pod:

    kubectl describe pod -n beginner-registry <pod-name>

Common causes:

- Image name is wrong
- Image tag is wrong
- Registry login server is wrong
- Registry requires authentication
- `imagePullSecret` is missing
- ACR `AcrPull` permission is missing
- Image does not exist in the registry

### ACR image cannot be pulled

Verify the image exists:

    az acr repository list --name <acr-name> --output table

    az acr repository show-tags \
      --name <acr-name> \
      --repository <repository-name> \
      --output table

Check AKS to ACR access:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

If needed, attach ACR:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

Image format should be:

    <acr-login-server>/<repository>:<tag>

### Private external image cannot be pulled

Check that the secret exists:

    kubectl get secret registry-secret -n beginner-registry

Check the Deployment uses the secret:

    kubectl get deployment registry-demo -n beginner-registry -o yaml | grep -A3 imagePullSecrets

Check:

- Secret is in the same namespace as the Deployment
- Deployment references the secret
- Registry username/password/token is correct
- Registry server name is correct

### Pod is Pending

If the pod is Pending, check whether the node selector matches your node labels:

    kubectl get nodes --show-labels | grep "workload=user" || true

If no node has the label, either label a node or remove the node selector from the Deployment manifest.

## Cleanup

Delete the lab namespace:

    kubectl delete namespace beginner-registry --ignore-not-found

This removes the Deployment, Pod, Service, and any `registry-secret` created in this namespace.

If you added the `workload=user` label only for this lab and want to remove it, run:

    kubectl label node <node-name> workload-

## Important note

This is a beginner lab.

Start with the public image first.

After the basic deployment works, change the image to ACR or another registry to learn how image pull permissions affect Kubernetes deployments.
