# Beginner Lab 02 - Expose NGINX with Gateway API

This lab shows how to deploy a public NGINX image to AKS and expose it through Gateway API.

This is a standalone beginner lab.

It uses an existing shared Gateway.

It does not require Docker Desktop.

It does not require a container registry.

## Lab goal

By the end of this lab, you should have:

- A Kubernetes namespace named `beginner-nginx`
- A Deployment named `nginx`
- A Service named `nginx`
- An HTTPRoute named `nginx-route`
- Traffic routed through the shared Gateway
- The default NGINX welcome page accessible through the Gateway external IP

The expected browser URL is:

    http://<gateway-external-ip>

## What you will learn

You will learn:

- How Gateway API fits into Kubernetes traffic routing
- How to deploy a public container image
- How to create a Kubernetes Service
- How to create an HTTPRoute
- How to attach an HTTPRoute to an existing Gateway
- How to verify Gateway and HTTPRoute status
- How to access an application through a Gateway external IP
- How to clean up lab resources safely

## Lab architecture

The flow is:

    Browser
      |
      v
    Gateway external IP
      |
      v
    Gateway: platform-gateway/public-gateway
      |
      v
    HTTPRoute: beginner-nginx/nginx-route
      |
      v
    Service: beginner-nginx/nginx
      |
      v
    Pod: nginx

The shared Gateway is:

    platform-gateway/public-gateway

The application namespace is:

    beginner-nginx

## What this lab requires

You need:

- kubectl
- Access to an AKS cluster
- Gateway API CRDs installed
- A Gateway API controller installed
- An existing Gateway named `public-gateway` in namespace `platform-gateway`
- A terminal
- A web browser

This lab does not require:

- Docker Desktop
- Azure Container Registry
- A custom container image
- A Kubernetes LoadBalancer Service created by this lab

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

Check that Gateway API resources are available:

    kubectl api-resources | grep -E 'gateway|httproute'

Check the Gateway controller pods:

    kubectl get pods -n nginx-gateway

Check the shared Gateway:

    kubectl get gateway public-gateway -n platform-gateway

Expected:

    Gateway controller pods are Running
    public-gateway exists
    public-gateway has Programmed=True or an accepted/healthy status

To inspect Gateway status in more detail:

    kubectl describe gateway public-gateway -n platform-gateway

## Files in this lab

This lab includes:

    manifests/
      Kubernetes manifests for namespace, deployment, service, and HTTPRoute

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml
    manifests/httproute.yaml

The Deployment uses this public image:

    nginx:1.27-alpine

The HTTPRoute attaches to:

    platform-gateway/public-gateway

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

    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/namespace.yaml

Apply the application and route resources:

    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/deployment.yaml
    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/service.yaml
    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/httproute.yaml

The namespace is applied first because Deployments, Services, and HTTPRoutes are namespaced resources.

## Verify resources

Check the namespace:

    kubectl get namespace beginner-nginx

Check pods:

    kubectl get pods -n beginner-nginx -o wide

Check the Deployment:

    kubectl get deployment nginx -n beginner-nginx

Check the Service:

    kubectl get svc nginx -n beginner-nginx

Check the HTTPRoute:

    kubectl get httproute nginx-route -n beginner-nginx

Check the Gateway:

    kubectl get gateway public-gateway -n platform-gateway

Expected:

    namespace exists
    pod status is Running
    deployment shows available replicas
    service exists
    HTTPRoute exists
    Gateway has an address and healthy status

## Access the app

Get the Gateway external address:

    kubectl get gateway public-gateway -n platform-gateway

Open the Gateway address in a browser:

    http://<gateway-external-ip>

Expected:

    The default NGINX welcome page should appear.

You can also test with curl:

    curl http://<gateway-external-ip>

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

### Service has no endpoints

Check endpoints:

    kubectl get endpoints nginx -n beginner-nginx

If endpoints are empty, the Service selector may not match pod labels.

Check pod labels:

    kubectl get pods -n beginner-nginx --show-labels

Check Service selector:

    kubectl describe svc nginx -n beginner-nginx

### HTTPRoute is not attached

Describe the HTTPRoute:

    kubectl describe httproute nginx-route -n beginner-nginx

Look for Accepted and ResolvedRefs conditions.

Also check the Gateway:

    kubectl describe gateway public-gateway -n platform-gateway

### Gateway has no external address

Check the Gateway:

    kubectl get gateway public-gateway -n platform-gateway

Check the Gateway controller pods:

    kubectl get pods -n nginx-gateway

The external address may take a few minutes to appear.

### Page does not load

Check all related resources:

    kubectl get pods -n beginner-nginx
    kubectl get svc -n beginner-nginx
    kubectl get httproute -n beginner-nginx
    kubectl get gateway public-gateway -n platform-gateway

Common issues:

- Pod is not Running
- Service selector does not match pod labels
- HTTPRoute is not accepted by the Gateway
- Gateway has no external address yet
- backendRef service name or port is wrong

## Cleanup

Delete the lab resources:

    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/httproute.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/service.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/deployment.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/namespace.yaml --ignore-not-found

This removes only the beginner lab app resources.

It does not delete the shared platform Gateway.

If you added the `workload=user` label only for this lab and want to remove it, run:

    kubectl label node <node-name> workload-

## Important note

This is a beginner lab.

It uses Gateway API to show external HTTP routing through an existing shared Gateway.

Do not delete shared Gateway or Gateway controller resources unless you created them and know they are not used by anything else.
