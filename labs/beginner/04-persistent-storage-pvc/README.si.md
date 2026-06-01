# Beginner Lab 04 - Persistent Storage with PVC

මෙම lab එකෙන් Kubernetes PersistentVolumeClaim එකක් use කරලා persistent storage use කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone beginner lab එකක්.

ඔයා NGINX pod එකකට persistent storage attach කරලා, ඒ storage එකෙන් custom HTML page එකක් serve කරනවා.

HTML file එක initContainer එකක් persistent volume එකට write කරනවා.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `beginner-storage` කියන Kubernetes namespace එකක්
- `nginx-html-pvc` කියන PersistentVolumeClaim එකක්
- `nginx-storage` කියන Deployment එකක්
- `nginx-storage` කියන Service එකක්
- PVC mount කරන running NGINX pod එකක්
- Persistent storage එකෙන් serve වෙන custom HTML page එකක්
- Pod lifecycle සහ storage lifecycle වෙනස් කියලා basic understanding එකක්

Local test URL එක:

    http://localhost:8082

Expected page text:

    Hello from AKS Persistent Storage Lab

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- PersistentVolumeClaim කියන්නේ මොකක්ද
- Pod එකකට persistent storage mount කරන විදිය
- Kubernetes dynamically storage provision කරන විදිය
- PVC status verify කරන විදිය
- Pod recreation එකෙන් පස්සේ data persistence test කරන විදිය
- initContainer එකක් mounted volume එකක content prepare කරන විදිය
- Storage resources safely clean up කරන විදිය

## Lab architecture

Flow එක:

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

InitContainer එක mounted volume එකට `index.html` write කරනවා.

NGINX container එක ඒ file එක මේ path එකෙන් serve කරනවා:

    /usr/share/nginx/html

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- AKS cluster access
- Default StorageClass එකක්, හෝ use කරන්න පුළුවන් StorageClass එකක්
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- Custom container image එකක්
- Gateway API

## Install required local tools

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

## Check local tools and AKS access

Continue කරන්න කලින් kubectl ට AKS cluster එකට connect වෙන්න පුළුවන්ද verify කරන්න:

    kubectl get nodes

Expected:

    Nodes Ready status එකෙන් පෙන්විය යුතුයි.

StorageClasses check කරන්න:

    kubectl get storageclass

Expected:

    අවම වශයෙන් StorageClass එකක් තියෙන්න ඕන.

Default StorageClass එක මොකක්ද check කරන්න:

    kubectl get storageclass

මේක බලන්න:

    (default)

මෙම lab එක PVC එකේ `storageClassName` specify කරන්නේ නැති නිසා default StorageClass එක use කරනවා.

## Files in this lab

මෙම lab එකේ files:

    manifests/
      Namespace, PVC, deployment, සහ service සඳහා Kubernetes manifests

Files:

    manifests/namespace.yaml
    manifests/pvc.yaml
    manifests/deployment.yaml
    manifests/service.yaml

PVC එක request කරන්නේ:

    1Gi

Deployment එක use කරන්නේ:

    busybox:1.36
    nginx:1.27-alpine

## Important node selector note

Deployment එකේ මේ node selector එක තියෙනවා:

    nodeSelector:
      workload: user

ඒ කියන්නේ pod එක schedule වෙන්නේ මේ label එක තියෙන nodes වලට විතරයි:

    workload=user

ඔයාගේ nodes වල ඒ label එක තියෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඔයාගේ cluster එකේ මේ label එක නැත්නම්, worker node එකකට label එක add කරන්න හෝ manifest එකෙන් `nodeSelector` remove කරන්න.

මෙම lab එකට node එකක් label කරන්න:

    kubectl get nodes

Node name එකක් තෝරලා run කරන්න:

    kubectl label node <node-name> workload=user --overwrite

## Important storage note

PersistentVolumeClaim එකක් dynamic provisioning හරහා cloud storage create කරන්න පුළුවන්.

AKS වලදී මෙය සාමාන්‍යයෙන් Azure Disk එකක් මත backed වෙනවා.

PVC delete කළාම StorageClass reclaim policy එක අනුව underlying disk එකත් delete වෙන්න පුළුවන්.

Reclaim policy check කරන්න:

    kubectl get storageclass

වැඩි විස්තර සඳහා:

    kubectl describe storageclass <storage-class-name>

මෙම lab එක learning purpose එකට පමණයි.

මෙම lab එකට production data use කරන්න එපා.

## Deploy the lab

මෙම commands repository root එකේ සිට run කරන්න.

මුලින් namespace එක apply කරන්න:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

PVC එක apply කරන්න:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Application resources apply කරන්න:

    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml
    kubectl apply -f labs/beginner/04-persistent-storage-pvc/manifests/service.yaml

## Verify resources

Namespace එක check කරන්න:

    kubectl get namespace beginner-storage

PVC එක check කරන්න:

    kubectl get pvc -n beginner-storage

Expected:

    STATUS is Bound

Pods check කරන්න:

    kubectl get pods -n beginner-storage -o wide

Deployment එක check කරන්න:

    kubectl get deployment nginx-storage -n beginner-storage

Service එක check කරන්න:

    kubectl get svc nginx-storage -n beginner-storage

Expected:

    namespace exists
    PVC status is Bound
    pod status is Running
    deployment shows available replicas
    service type is ClusterIP

## Access the app locally

Port-forward use කරන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Browser එකෙන් මේ URL එක open කරන්න:

    http://localhost:8082

Expected page text:

    Hello from AKS Persistent Storage Lab

තවත් terminal එකකින් curl use කරලා test කරන්නත් පුළුවන්:

    curl http://localhost:8082

Port-forward stop කරන්න:

    Ctrl+C

## Test persistence

Pod name එක ගන්න:

    kubectl get pods -n beginner-storage

Pod එක delete කරන්න:

    kubectl delete pod <pod-name> -n beginner-storage

Deployment එක new pod එකක් create කරනකම් wait කරන්න:

    kubectl get pods -n beginner-storage -w

New pod එක Running වුණාට පස්සේ `Ctrl+C` press කරන්න.

අවශ්‍ය නම් නැවත port-forward කරන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

නැවත open කරන්න:

    http://localhost:8082

Expected:

    Custom page එක තවම available වෙන්න ඕන, මොකද එය persistent volume එකේ stored වෙලා තියෙන නිසා.

## How it works

PVC එක storage request කරන්නේ:

    1Gi

Kubernetes PVC එක PersistentVolume එකකට bind කරනවා.

Pod එක NGINX container එකට PVC එක මේ path එකට mount කරනවා:

    /usr/share/nginx/html

InitContainer එක ඒ same PVC එක මේ path එකට mount කරනවා:

    /html

InitContainer එක write කරන්නේ:

    /html/index.html

NGINX ඒ same file එක persistent volume එකෙන් serve කරනවා.

Pod එක delete කළාම Deployment එක new pod එකක් create කරනවා.

PVC එක pod එකෙන් වෙනම පවතින නිසා stored file එක තවම available.

## Troubleshooting

### PVC is Pending

PVC එක check කරන්න:

    kubectl get pvc -n beginner-storage
    kubectl describe pvc nginx-html-pvc -n beginner-storage

StorageClasses check කරන්න:

    kubectl get storageclass

Common causes:

- Default StorageClass එකක් නැහැ
- StorageClass storage provision කරන්න බැහැ
- Cloud provider storage quota හෝ permissions issue

### Pod is not Running

Pod එක check කරන්න:

    kubectl get pods -n beginner-storage
    kubectl describe pod -n beginner-storage <pod-name>

Logs check කරන්න:

    kubectl logs -n beginner-storage <pod-name>

### Pod is Pending

Pod එක Pending නම්, node selector එක node labels සමඟ match වෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඒ label එක තියෙන node එකක් නැත්නම්, node එකකට label එක add කරන්න හෝ Deployment manifest එකෙන් node selector remove කරන්න.

### Init container failed

InitContainer logs check කරන්න:

    kubectl logs -n beginner-storage <pod-name> -c write-html

Pod describe කරන්න:

    kubectl describe pod -n beginner-storage <pod-name>

### Local page does not open

Port-forward running ද බලන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Port `8082` already use වෙනවා නම්, වෙන local port එකක් use කරන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8083:80

ඊට පස්සේ open කරන්න:

    http://localhost:8083

## Cleanup

Lab namespace එක delete කරන්න:

    kubectl delete namespace beginner-storage --ignore-not-found

මෙයින් මෙම lab එකෙන් create කළ Deployment, Pod, Service, සහ PVC remove වෙනවා.

Important:

PVC delete වුණාම dynamically provision කළ PersistentVolume හෝ cloud disk එක StorageClass reclaim policy එක අනුව delete වෙන්න පුළුවන්.

Cleanup verify කරන්න:

    kubectl get namespace beginner-storage

`workload=user` label එක මෙම lab එකට විතරක් add කළා නම් සහ remove කරන්න ඕන නම් run කරන්න:

    kubectl label node <node-name> workload-

## Important note

මෙය beginner lab එකක්.

මෙය basic persistent storage behavior demonstrate කරනවා.

Production data use කරන්න එපා.

PVC delete කරන විට storage cleanup behavior එක StorageClass reclaim policy එක අනුව වෙනස් වෙන නිසා careful වෙන්න.
