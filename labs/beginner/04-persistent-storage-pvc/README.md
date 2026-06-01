# Beginner Lab 04 - Persistent Storage with PVC

This lab shows how to use persistent storage with a Kubernetes PersistentVolumeClaim.

This is a standalone beginner lab.

You will attach persistent storage to an NGINX pod and serve a custom HTML page from that storage.

The HTML file is written to the persistent volume by an initContainer.

## Lab goal

By the end of this lab, you should have:

- A Kubernetes namespace named `beginner-storage`
- A PersistentVolumeClaim named `nginx-html-pvc`
- A Deployment named `nginx-storage`
- A Service named `nginx-storage`
- One running NGINX pod that mounts the PVC
- A custom HTML page served from persistent storage
- A basic understanding of how pod lifecycle and storage lifecycle are different

The local test URL is:

    http://localhost:8082

Expected page text:

    Hello from AKS Persistent Storage Lab

## What you will learn

You will learn:

- What a PersistentVolumeClaim is
- How a pod mounts persistent storage
- How Kubernetes dynamically provisions storage
- How to verify PVC status
- How to test data persistence after pod recreation
- How an initContainer can prepare content on a mounted volume
- How to clean up storage resources safely

## Lab architecture

The flow is:

    AKS cluster
      |
      v
    Namespace: beginner-storage
      |
      v
    PersistentVolumeClaim: nginx-html-pvc
      |
      v
    PersistentVolume
      |
      v
    Pod volume mount
      |
      v
    /usr/share/nginx/html
      |
      v
    NGINX Service
      |
      v
    kubectl port-forward
      |
      v
    http://localhost:8082

The initContainer writes `index.html` into the mounted volume.

The NGINX container serves that file from:

    /usr/share/nginx/html

## What this lab requires

You need:

- kubectl
- Access to an AKS cluster
- A default StorageClass, or a StorageClass you can use
- A terminal
- A web browser

This lab does not require:

- Docker Desktop
- Azure Container Registry
- A custom container image
- Gateway API

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

Check StorageClasses:

    kubectl get storageclass

Expected:

    At least one StorageClass should exist.

Check which StorageClass is default:

    kubectl get storageclass

Look for:

    (default)

This lab uses the default StorageClass because the PVC does not specify `storageClassName`.

## Files in this lab

This lab includes:

    manifests/
      Kubernetes manifests for namespace, PVC, deployment, and service

Files:

    manifests/namespace.yaml
    manifests/pvc.yaml
    manifests/deployment.yaml
    manifests/service.yaml

The PVC requests:

    1Gi

The Deployment uses:

    busybox:1.36
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

## Important storage note

A PersistentVolumeClaim can create cloud storage through dynamic provisioning.

On AKS, this is commonly backed by Azure Disk.

Deleting a PVC can also delete the underlying disk, depending on the StorageClass reclaim policy.

Check the reclaim policy:

    kubectl get storageclass

For more detail:

    kubectl describe storageclass <storage-class-name>

This lab is for learning only.

Do not use production data for this lab.

## Deploy the lab

Run these commands from the repository root.

Apply the namespace first:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

Apply the PVC:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Apply the application resources:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml
    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/service.yaml

## Verify resources

Check the namespace:

    kubectl get namespace beginner-storage

Check the PVC:

    kubectl get pvc -n beginner-storage

Expected:

    STATUS is Bound

Check pods:

    kubectl get pods -n beginner-storage -o wide

Check the Deployment:

    kubectl get deployment nginx-storage -n beginner-storage

Check the Service:

    kubectl get svc nginx-storage -n beginner-storage

Expected:

    namespace exists
    PVC status is Bound
    pod status is Running
    deployment shows available replicas
    service type is ClusterIP

## Access the app locally

Use port-forward:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Open this URL in your browser:

    http://localhost:8082

Expected page text:

    Hello from AKS Persistent Storage Lab

You can also test with curl from another terminal:

    curl http://localhost:8082

Stop the port-forward with:

    Ctrl+C

## Test persistence

Get the pod name:

    kubectl get pods -n beginner-storage

Delete the pod:

    kubectl delete pod <pod-name> -n beginner-storage

Wait for the Deployment to create a new pod:

    kubectl get pods -n beginner-storage -w

Press `Ctrl+C` after the new pod is Running.

Port-forward again if needed:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Open again:

    http://localhost:8082

Expected:

    The custom page should still be available because it is stored on the persistent volume.

## How it works

The PVC requests storage:

    1Gi

Kubernetes binds the PVC to a PersistentVolume.

The pod mounts the PVC at this path for the NGINX container:

    /usr/share/nginx/html

The initContainer mounts the same PVC at:

    /html

The initContainer writes:

    /html/index.html

NGINX serves that same file from the persistent volume.

When the pod is deleted, the Deployment creates a new pod.

The PVC remains separate from the pod, so the stored file remains available.

## Troubleshooting

### PVC is Pending

Check the PVC:

    kubectl get pvc -n beginner-storage
    kubectl describe pvc nginx-html-pvc -n beginner-storage

Check StorageClasses:

    kubectl get storageclass

Common causes:

- No default StorageClass exists
- StorageClass cannot provision storage
- Cloud provider storage quota or permissions issue

### Pod is not Running

Check the pod:

    kubectl get pods -n beginner-storage
    kubectl describe pod -n beginner-storage <pod-name>

Check logs:

    kubectl logs -n beginner-storage <pod-name>

### Pod is Pending

If the pod is Pending, check whether the node selector matches your node labels:

    kubectl get nodes --show-labels | grep "workload=user" || true

If no node has the label, either label a node or remove the node selector from the Deployment manifest.

### Init container failed

Check initContainer logs:

    kubectl logs -n beginner-storage <pod-name> -c write-html

Describe the pod:

    kubectl describe pod -n beginner-storage <pod-name>

### Local page does not open

Make sure port-forward is running:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

If port `8082` is already in use, use another local port:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8083:80

Then open:

    http://localhost:8083

## Cleanup

Delete the lab namespace:

    kubectl delete namespace beginner-storage --ignore-not-found

This removes the Deployment, Pod, Service, and PVC created by this lab.

Important:

Deleting the PVC may delete the dynamically provisioned PersistentVolume or cloud disk, depending on the StorageClass reclaim policy.

Verify cleanup:

    kubectl get namespace beginner-storage

If you added the `workload=user` label only for this lab and want to remove it, run:

    kubectl label node <node-name> workload-

## Important note

This is a beginner lab.

It demonstrates basic persistent storage behavior.

Do not use production data.

Be careful when deleting PVCs because storage cleanup behavior depends on the StorageClass reclaim policy.
