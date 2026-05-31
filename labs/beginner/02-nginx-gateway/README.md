# Beginner Lab 02 - Expose NGINX with Gateway API

This lab shows how to deploy a simple public Docker Hub image to AKS and expose it using Gateway API.

## What you will learn

- Create a Kubernetes namespace
- Deploy a public container image
- Create a Kubernetes Service
- Create an HTTPRoute
- Attach the HTTPRoute to the shared platform Gateway
- Verify the application in AKS
- Access the application through the Gateway external IP

## What this lab uses

- AKS
- Public Docker Hub image
- Kubernetes Deployment
- Kubernetes Service
- Gateway API HTTPRoute
- Existing shared Gateway

Shared Gateway:

    platform-gateway/public-gateway

## Prerequisites

Before starting, make sure:

- AKS cluster is running
- NGINX Gateway Fabric is running
- public-gateway is Programmed=True

Check:

    kubectl get nodes
    kubectl get pods -n nginx-gateway
    kubectl get gateway -n platform-gateway

## Deploy the lab

From the repository root, apply the namespace first:

    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/namespace.yaml

Then apply the application resources:

    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/service.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/httproute.yaml

Why apply the namespace first?

Kubernetes needs the namespace to exist before creating namespaced resources such as Deployments, Services, and HTTPRoutes.

## Verify resources

Check namespace:

    kubectl get ns beginner-nginx

Check pods:

    kubectl get pods -n beginner-nginx

Check service:

    kubectl get svc -n beginner-nginx

Check HTTPRoute:

    kubectl get httproute -n beginner-nginx

Check Gateway:

    kubectl get gateway -n platform-gateway

## Access the app

Get the Gateway external IP:

    kubectl get gateway public-gateway -n platform-gateway

Open the external IP in a browser:

    http://<gateway-external-ip>

You should see the default NGINX welcome page.

## Troubleshooting

If the app does not load, check the pod:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Check the Service endpoints:

    kubectl get endpoints -n beginner-nginx

Check the HTTPRoute:

    kubectl describe httproute nginx-route -n beginner-nginx

Common issues:

- Pod is not Running
- Service port does not match container port
- HTTPRoute backendRef service name is wrong
- Gateway is not Programmed
- Gateway external IP is not ready yet

## Cleanup

Delete the lab resources:

    kubectl delete -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/

This removes only the lab app.

It does not delete the shared platform Gateway.
