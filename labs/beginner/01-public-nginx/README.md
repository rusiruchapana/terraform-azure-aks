# Beginner Lab 01 - Deploy Public NGINX Image

This lab shows how to deploy a public Docker Hub image to AKS and access it from your laptop using `kubectl port-forward`.

This is a standalone beginner lab.

It does not use Gateway API.

It does not require a container registry.

It does not require Docker Desktop.

## Lab goal

By the end of this lab, you should have:

- A Kubernetes namespace named `beginner-nginx`
- A Deployment named `nginx`
- A Service named `nginx`
- One running NGINX pod
- The default NGINX welcome page accessible from your laptop

The local test URL is:

    http://localhost:8080

## What you will learn

You will learn:

- How to create a Kubernetes namespace
- How to deploy a public Docker Hub image
- How to create a Kubernetes Deployment
- How to create a Kubernetes Service
- How to verify pods and services
- How to access an app locally using `kubectl port-forward`
- How to clean up lab resources safely

## Lab architecture

The flow is:

    Your laptop
      |
      | kubectl apply
      v
    AKS cluster
      |
      v
    Namespace: beginner-nginx
      |
      v
    Deployment: nginx
      |
      v
    Pod: nginx
      |
      v
    Service: nginx
      |
      v
    kubectl port-forward
      |
      v
    http://localhost:8080

The Service is a `ClusterIP` service.

That means it is reachable inside the cluster.

For this beginner lab, you access it from your laptop using `kubectl port-forward`.

## What this lab requires

You need:

- kubectl
- Access to an AKS cluster
- A terminal
- A web browser

This lab does not require:

- Azure CLI commands during the lab
- Docker Desktop
- Azure Container Registry
- Gateway API
- Public LoadBalancer service

## Install required local tools

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

## Check local tools and AKS access

Before continuing, verify that kubectl can reach your AKS cluster:

    kubectl get nodes

Expected:

    Nodes should show Ready status.

If `kubectl get nodes` fails, get AKS credentials first from your AKS environment setup.

## Files in this lab

This lab includes:

    manifests/
      Kubernetes manifests for the namespace, deployment, and service

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml

The Deployment uses this public image:

    nginx:1.27-alpine

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

## Deploy the lab

Run these commands from the repository root.

Apply the namespace first:

    kubectl apply -f labs/beginner/01-public-nginx/manifests/namespace.yaml

Apply the app resources:

    kubectl apply -f labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl apply -f labs/beginner/01-public-nginx/manifests/service.yaml

## Verify resources

Check the namespace:

    kubectl get namespace beginner-nginx

Check pods:

    kubectl get pods -n beginner-nginx -o wide

Check the Deployment:

    kubectl get deployment nginx -n beginner-nginx

Check the Service:

    kubectl get svc nginx -n beginner-nginx

Expected:

    namespace exists
    pod status is Running
    deployment shows available replicas
    service type is ClusterIP

## Access the app locally

Use port-forward:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

Open this URL in your browser:

    http://localhost:8080

Expected:

    The default NGINX welcome page should appear.

You can also test with curl from another terminal:

    curl http://localhost:8080

Stop the port-forward with:

    Ctrl+C

## Troubleshooting

### Pod is not Running

Check the pod:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Look at the Events section.

### Pod is Pending

If the pod is Pending, check whether the node selector matches your node labels:

    kubectl get nodes --show-labels | grep "workload=user" || true

If no node has the label, either label a node or remove the node selector from the Deployment manifest.

### Image cannot be pulled

Check the pod events:

    kubectl describe pod -n beginner-nginx <pod-name>

The image should be:

    nginx:1.27-alpine

### Service does not route to the pod

Check the Service:

    kubectl get svc nginx -n beginner-nginx
    kubectl describe svc nginx -n beginner-nginx

Check endpoints:

    kubectl get endpoints nginx -n beginner-nginx

If endpoints are empty, the Service selector may not match pod labels.

### Local page does not open

Make sure the port-forward command is still running:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

If port `8080` is already in use, use another local port:

    kubectl port-forward svc/nginx -n beginner-nginx 8081:80

Then open:

    http://localhost:8081

## Cleanup

Delete the lab namespace:

    kubectl delete namespace beginner-nginx --ignore-not-found

This removes the Deployment, Pod, and Service created by this lab.

If you added the `workload=user` label only for this lab and want to remove it, run:

    kubectl label node <node-name> workload-

## Important note

This is a beginner lab.

It uses a public NGINX image so you can focus on Kubernetes basics before working with registries, ingress, storage, or troubleshooting scenarios.
