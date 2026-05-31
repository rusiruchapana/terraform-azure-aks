# Beginner Lab 01 - Deploy Public NGINX Image

This lab shows how to deploy a public Docker Hub image to AKS.

This is the first beginner lab.

It does not use Gateway API yet.

You will access the application locally using kubectl port-forward.

## What you will learn

- Create a Kubernetes namespace
- Deploy a public Docker Hub image
- Create a Kubernetes Service
- Verify pods and services
- Access the app using port-forward
- Clean up lab resources safely

## What this lab uses

- AKS
- Public Docker Hub image
- Kubernetes Namespace
- Kubernetes Deployment
- Kubernetes Service
- kubectl port-forward

## Prerequisites

Before starting, make sure the AKS cluster is running:

    kubectl get nodes

Expected:

    STATUS   Ready

## Deploy the lab

From the repository root, apply the namespace first:

    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/namespace.yaml

Then apply the app resources:

    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/service.yaml

## Verify resources

Check pods:

    kubectl get pods -n beginner-nginx

Check service:

    kubectl get svc -n beginner-nginx

Expected:

    Pod should be Running
    Service should be ClusterIP

## Access the app locally

Use port-forward:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

Open in browser:

    http://localhost:8080

You should see the default NGINX welcome page.

## Troubleshooting

If the app does not load, check the pod:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Check the Service:

    kubectl get svc -n beginner-nginx

Check Service endpoints:

    kubectl get endpoints -n beginner-nginx

Common issues:

- Pod is not Running
- Image cannot be pulled
- Service selector does not match pod labels
- Port-forward command is not running
- Local port 8080 is already in use

## Cleanup

Delete the lab resources:

    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/service.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/namespace.yaml

This removes only the lab resources.
