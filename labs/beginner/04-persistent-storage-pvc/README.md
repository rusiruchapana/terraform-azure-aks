# Beginner Lab 04 - Persistent Storage with PVC

This lab shows how to use persistent storage with a Kubernetes PersistentVolumeClaim.

In earlier labs, the application did not store data.

In this lab, you will attach persistent storage to an NGINX pod and serve a custom HTML page from that storage.

## What you will learn

- What a PersistentVolumeClaim is
- How a pod mounts persistent storage
- How Kubernetes dynamically provisions storage
- How to verify PVC status
- How to test data persistence after pod recreation
- How to clean up storage resources safely

## What this lab uses

- AKS
- Kubernetes Namespace
- PersistentVolumeClaim
- Deployment
- Service
- NGINX public image
- kubectl port-forward

## Important storage note

AKS usually provides a default StorageClass.

Check available StorageClasses:

    kubectl get storageclass

This lab uses the default StorageClass by not specifying storageClassName.

## Deploy the lab

From the repository root, apply the namespace first:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

Then apply the PVC:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Then apply the application resources:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/service.yaml

## Verify resources

Check PVC:

    kubectl get pvc -n beginner-storage

Expected:

    STATUS   Bound

Check pods:

    kubectl get pods -n beginner-storage

Check service:

    kubectl get svc -n beginner-storage

## Access the app locally

Use port-forward:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Open in browser:

    http://localhost:8082

You should see a page saying:

    Hello from AKS Persistent Storage Lab

## Test persistence

Get the pod name:

    kubectl get pods -n beginner-storage

Delete the pod:

    kubectl delete pod <pod-name> -n beginner-storage

Wait for the Deployment to create a new pod:

    kubectl get pods -n beginner-storage

Port-forward again if needed:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Open again:

    http://localhost:8082

The custom page should still be available because it is stored on the persistent volume.

## How it works

The PersistentVolumeClaim requests storage:

    1Gi

The pod mounts the PVC at:

    /usr/share/nginx/html

An initContainer writes index.html into that mounted volume.

NGINX then serves the HTML page from the persistent volume.

## Troubleshooting

Check PVC:

    kubectl get pvc -n beginner-storage
    kubectl describe pvc nginx-html-pvc -n beginner-storage

Check pod:

    kubectl get pods -n beginner-storage
    kubectl describe pod -n beginner-storage <pod-name>

Check logs:

    kubectl logs -n beginner-storage <pod-name>

Common issues:

- PVC is Pending
- No default StorageClass exists
- Pod cannot mount the volume
- Init container failed
- Local port 8082 is already in use

## Cleanup

Delete the app resources first:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/service.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml

Then delete the PVC:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Then delete the namespace:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

Important:

Deleting the PVC usually deletes the dynamically provisioned disk depending on the StorageClass reclaim policy.

This lab is for learning only.
