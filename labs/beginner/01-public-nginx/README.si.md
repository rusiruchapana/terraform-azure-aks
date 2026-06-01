# Beginner Lab 01 - Deploy Public NGINX Image

මෙම lab එකෙන් public Docker Hub image එකක් AKS වලට deploy කරලා, `kubectl port-forward` use කරලා laptop එකෙන් access කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone beginner lab එකක්.

මෙම lab එක Gateway API use කරන්නේ නැහැ.

මෙම lab එකට container registry එකක් අවශ්‍ය නැහැ.

මෙම lab එකට Docker Desktop අවශ්‍ය නැහැ.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `beginner-nginx` කියන Kubernetes namespace එකක්
- `nginx` කියන Deployment එකක්
- `nginx` කියන Service එකක්
- Running තත්ත්වයේ NGINX pod එකක්
- ඔයාගේ laptop එකෙන් access කළ හැකි default NGINX welcome page එක

Local test URL එක:

    http://localhost:8080

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Kubernetes namespace එකක් create කරන විදිය
- Public Docker Hub image එකක් deploy කරන විදිය
- Kubernetes Deployment එකක් create කරන විදිය
- Kubernetes Service එකක් create කරන විදිය
- Pods සහ Services verify කරන විදිය
- `kubectl port-forward` use කරලා app එක locally access කරන විදිය
- Lab resources safely clean up කරන විදිය

## Lab architecture

Flow එක:

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

Service එක `ClusterIP` service එකක්.

ඒ කියන්නේ එය cluster එක ඇතුළේ reachable.

මෙම beginner lab එකේදී ඔයාගේ laptop එකෙන් access කරන්න `kubectl port-forward` use කරනවා.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- AKS cluster access
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Lab එක කරන අතරතුර Azure CLI commands
- Docker Desktop
- Azure Container Registry
- Gateway API
- Public LoadBalancer service

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

`kubectl get nodes` fail වුණොත්, මුලින් ඔයාගේ AKS environment setup එකෙන් AKS credentials ගන්න.

## Files in this lab

මෙම lab එකේ files:

    manifests/
      Namespace, deployment, සහ service සඳහා Kubernetes manifests

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml

Deployment එක මේ public image එක use කරනවා:

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

## Deploy the lab

මෙම commands repository root එකේ සිට run කරන්න.

මුලින් namespace එක apply කරන්න:

    kubectl apply -f labs/beginner/01-public-nginx/manifests/namespace.yaml

App resources apply කරන්න:

    kubectl apply -f labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl apply -f labs/beginner/01-public-nginx/manifests/service.yaml

## Verify resources

Namespace එක check කරන්න:

    kubectl get namespace beginner-nginx

Pods check කරන්න:

    kubectl get pods -n beginner-nginx -o wide

Deployment එක check කරන්න:

    kubectl get deployment nginx -n beginner-nginx

Service එක check කරන්න:

    kubectl get svc nginx -n beginner-nginx

Expected:

    namespace exists
    pod status is Running
    deployment shows available replicas
    service type is ClusterIP

## Access the app locally

Port-forward use කරන්න:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

Browser එකෙන් මේ URL එක open කරන්න:

    http://localhost:8080

Expected:

    Default NGINX welcome page එක පේන්න ඕන.

තවත් terminal එකකින් curl use කරලා test කරන්නත් පුළුවන්:

    curl http://localhost:8080

Port-forward stop කරන්න:

    Ctrl+C

## Troubleshooting

### Pod is not Running

Pod එක check කරන්න:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Events section එක බලන්න.

### Pod is Pending

Pod එක Pending නම්, node selector එක node labels සමඟ match වෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඒ label එක තියෙන node එකක් නැත්නම්, node එකකට label එක add කරන්න හෝ Deployment manifest එකෙන් node selector remove කරන්න.

### Image cannot be pulled

Pod events check කරන්න:

    kubectl describe pod -n beginner-nginx <pod-name>

Image එක මෙය විය යුතුයි:

    nginx:1.27-alpine

### Service does not route to the pod

Service එක check කරන්න:

    kubectl get svc nginx -n beginner-nginx
    kubectl describe svc nginx -n beginner-nginx

Endpoints check කරන්න:

    kubectl get endpoints nginx -n beginner-nginx

Endpoints empty නම්, Service selector එක pod labels සමඟ match නොවිය හැකියි.

### Local page does not open

Port-forward command එක තවම run වෙනවද බලන්න:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

Port `8080` already use වෙනවා නම්, වෙන local port එකක් use කරන්න:

    kubectl port-forward svc/nginx -n beginner-nginx 8081:80

ඊට පස්සේ open කරන්න:

    http://localhost:8081

## Cleanup

Lab namespace එක delete කරන්න:

    kubectl delete namespace beginner-nginx --ignore-not-found

මෙයින් මෙම lab එකෙන් create කළ Deployment, Pod, සහ Service remove වෙනවා.

`workload=user` label එක මෙම lab එකට විතරක් add කළා නම් සහ remove කරන්න ඕන නම් run කරන්න:

    kubectl label node <node-name> workload-

## Important note

මෙය beginner lab එකක්.

මෙම lab එක public NGINX image එකක් use කරනවා, මොකද registries, ingress, storage, troubleshooting scenarios වලට යන්න කලින් Kubernetes basics focus කරන්න.
