# Beginner Lab 04 - Persistent Storage with PVC

මෙම lab එකෙන් Kubernetes PersistentVolumeClaim එකක් use කරලා pod restart/delete වුණත් data persist වෙන storage pattern එක ඉගෙන ගන්නවා.

Beginner labs වලදී මේක වැදගත්, මොකද stateless app එකක් සහ storage use කරන app එකක් අතර වෙනස මෙතනින් තේරෙන්න පටන් ගන්නවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- PersistentVolumeClaim කියන්නේ මොකක්ද
- Pod එකකට PVC එක mount කරන විදිය
- AKS default StorageClass එක use කරන විදිය
- Pod delete වුණත් volume data persist වෙන idea එක
- PVC, Pod, Service verify කරන විදිය
- Storage troubleshooting කරන විදිය

## What this lab uses

මෙම lab එක use කරන්නේ:

- AKS cluster
- Kubernetes Namespace
- PersistentVolumeClaim
- Deployment
- Service
- Azure disk backed dynamic provisioning
- `kubectl port-forward`

## Important storage note

StorageClass තියෙනවද බලන්න:

    kubectl get storageclass

AKS cluster වල සාමාන්‍යයෙන් default StorageClass එකක් තියෙනවා.

PVC එක create කළාම Kubernetes dynamically PersistentVolume එකක් provision කරනවා. AKS වලදී ඒක සාමාන්‍යයෙන් Azure Disk එකක් use කරනවා.

මෙම lab එක learning purpose එකට small PVC එකක් use කරනවා.

## Deploy the lab

Namespace එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

PVC එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Deployment සහ Service apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/service.yaml

Namespace එක වෙනම apply කරන එක safe. PVC සහ Deployment එක namespace එක මත depend වෙනවා.

## Verify resources

PVC status බලන්න:

    kubectl get pvc -n beginner-storage

Expected:

    PVC STATUS එක Bound වෙන්න ඕන.

Pods බලන්න:

    kubectl get pods -n beginner-storage

Expected:

    Pod STATUS එක Running වෙන්න ඕන.

Service බලන්න:

    kubectl get svc -n beginner-storage

Expected:

    nginx-storage service එක පේන්න ඕන.

## Access the app locally

Service එක local machine එකට port-forward කරන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Browser එකෙන් open කරන්න:

    http://localhost:8082

Expected:

    NGINX page එක load වෙන්න ඕන.

Port-forward stop කරන්න:

    Ctrl + C

## Test persistence

Pods list කරන්න:

    kubectl get pods -n beginner-storage

Pod name එක copy කරලා pod එක delete කරන්න:

    kubectl delete pod <pod-name> -n beginner-storage

Deployment එක automatically new pod එකක් create කරයි.

New pod එක Running වෙනවද බලන්න:

    kubectl get pods -n beginner-storage

ඊට පස්සේ service එක නැවත port-forward කරන්න:

    kubectl port-forward svc/nginx-storage -n beginner-storage 8082:80

Browser එකෙන් open කරන්න:

    http://localhost:8082

මෙම lab එකේ goal එක PVC lifecycle සහ pod replacement flow එක තේරුම් ගන්න එක. Pod delete වුණත් PVC resource එක වෙනම තියෙනවා.

## How it works

PVC එක Kubernetes වල persistent storage request එකක්.

Flow එක:

    PersistentVolumeClaim
      |
      v
    PersistentVolume
      |
      v
    Pod volumeMount
      |
      v
    Container filesystem path

Deployment එක pod recreate කළත් PVC එක namespace එකේ වෙනම resource එකක් විදියට පවතිනවා.

ඒ නිසා storage lifecycle එක Pod lifecycle එකට වඩා වෙනස්.

## Troubleshooting

PVC issue එකක් තියෙනවා නම් බලන්න:

    kubectl get pvc -n beginner-storage
    kubectl describe pvc nginx-html-pvc -n beginner-storage

Pod issue එකක් තියෙනවා නම් බලන්න:

    kubectl get pods -n beginner-storage
    kubectl describe pod -n beginner-storage <pod-name>

Logs බලන්න:

    kubectl logs -n beginner-storage <pod-name>

Common issues:

- PVC Pending
- StorageClass නැති වීම
- Pod volume mount issue
- Node scheduling issue

## Cleanup

Service delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/service.yaml

Deployment delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/deployment.yaml

PVC delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/pvc.yaml

Namespace delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/04-persistent-storage-pvc/manifests/namespace.yaml

PVC delete කළාම underlying persistent volume / disk cleanup වෙන්න පුළුවන්, StorageClass reclaim policy එක අනුව.

