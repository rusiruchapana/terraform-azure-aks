# Beginner Lab 02 - Expose NGINX with Gateway API

මෙම lab එකෙන් public NGINX image එකක් AKS වලට deploy කරලා Gateway API හරහා expose කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone beginner lab එකක්.

මෙම lab එක existing shared Gateway එකක් use කරනවා.

මෙම lab එකට Docker Desktop අවශ්‍ය නැහැ.

මෙම lab එකට container registry එකක් අවශ්‍ය නැහැ.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `beginner-nginx` කියන Kubernetes namespace එකක්
- `nginx` කියන Deployment එකක්
- `nginx` කියන Service එකක්
- `nginx-route` කියන HTTPRoute එකක්
- Shared Gateway හරහා route වෙන traffic
- Gateway external IP එකෙන් access කළ හැකි default NGINX welcome page එක

Expected browser URL එක:

    http://<gateway-external-ip>

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Gateway API Kubernetes traffic routing වලට fit වෙන විදිය
- Public container image එකක් deploy කරන විදිය
- Kubernetes Service එකක් create කරන විදිය
- HTTPRoute එකක් create කරන විදිය
- HTTPRoute එකක් existing Gateway එකකට attach කරන විදිය
- Gateway සහ HTTPRoute status verify කරන විදිය
- Gateway external IP එකෙන් application එක access කරන විදිය
- Lab resources safely clean up කරන විදිය

## Lab architecture

Flow එක:

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

Shared Gateway එක:

    platform-gateway/public-gateway

Application namespace එක:

    beginner-nginx

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- AKS cluster access
- Gateway API CRDs installed වීම
- Gateway API controller installed වීම
- `platform-gateway` namespace එකේ `public-gateway` කියන existing Gateway එක
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- Custom container image එකක්
- මෙම lab එකෙන් create කරන Kubernetes LoadBalancer Service එකක්

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

Gateway API resources available ද check කරන්න:

    kubectl api-resources | grep -E 'gateway|httproute'

Gateway controller pods check කරන්න:

    kubectl get pods -n nginx-gateway

Shared Gateway එක check කරන්න:

    kubectl get gateway public-gateway -n platform-gateway

Expected:

    Gateway controller pods Running වෙන්න ඕන
    public-gateway exists වෙන්න ඕන
    public-gateway Programmed=True හෝ accepted/healthy status එකක තියෙන්න ඕන

Gateway status වැඩි විස්තර බලන්න:

    kubectl describe gateway public-gateway -n platform-gateway

## Files in this lab

මෙම lab එකේ files:

    manifests/
      Namespace, deployment, service, සහ HTTPRoute සඳහා Kubernetes manifests

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml
    manifests/httproute.yaml

Deployment එක මේ public image එක use කරනවා:

    nginx:1.27-alpine

HTTPRoute එක attach වෙන්නේ:

    platform-gateway/public-gateway

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

    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/namespace.yaml

Application සහ route resources apply කරන්න:

    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/deployment.yaml
    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/service.yaml
    kubectl apply -f labs/beginner/02-nginx-gateway/manifests/httproute.yaml

Namespace එක මුලින් apply කරනවා, මොකද Deployments, Services, සහ HTTPRoutes namespaced resources නිසා.

## Verify resources

Namespace එක check කරන්න:

    kubectl get namespace beginner-nginx

Pods check කරන්න:

    kubectl get pods -n beginner-nginx -o wide

Deployment එක check කරන්න:

    kubectl get deployment nginx -n beginner-nginx

Service එක check කරන්න:

    kubectl get svc nginx -n beginner-nginx

HTTPRoute එක check කරන්න:

    kubectl get httproute nginx-route -n beginner-nginx

Gateway එක check කරන්න:

    kubectl get gateway public-gateway -n platform-gateway

Expected:

    namespace exists
    pod status is Running
    deployment shows available replicas
    service exists
    HTTPRoute exists
    Gateway has an address and healthy status

## Access the app

Gateway external address එක ගන්න:

    kubectl get gateway public-gateway -n platform-gateway

Browser එකෙන් Gateway address එක open කරන්න:

    http://<gateway-external-ip>

Expected:

    Default NGINX welcome page එක පේන්න ඕන.

curl use කරලා test කරන්නත් පුළුවන්:

    curl http://<gateway-external-ip>

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

### Service has no endpoints

Endpoints check කරන්න:

    kubectl get endpoints nginx -n beginner-nginx

Endpoints empty නම්, Service selector එක pod labels සමඟ match නොවිය හැකියි.

Pod labels check කරන්න:

    kubectl get pods -n beginner-nginx --show-labels

Service selector check කරන්න:

    kubectl describe svc nginx -n beginner-nginx

### HTTPRoute is not attached

HTTPRoute describe කරන්න:

    kubectl describe httproute nginx-route -n beginner-nginx

Accepted සහ ResolvedRefs conditions බලන්න.

Gateway එකත් check කරන්න:

    kubectl describe gateway public-gateway -n platform-gateway

### Gateway has no external address

Gateway එක check කරන්න:

    kubectl get gateway public-gateway -n platform-gateway

Gateway controller pods check කරන්න:

    kubectl get pods -n nginx-gateway

External address එක appear වෙන්න විනාඩි කිහිපයක් යන්න පුළුවන්.

### Page does not load

Related resources සියල්ල check කරන්න:

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

Lab resources delete කරන්න:

    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/httproute.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/service.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/deployment.yaml --ignore-not-found
    kubectl delete -f labs/beginner/02-nginx-gateway/manifests/namespace.yaml --ignore-not-found

මෙයින් beginner lab app resources පමණක් remove වෙනවා.

Shared platform Gateway එක delete වෙන්නේ නැහැ.

`workload=user` label එක මෙම lab එකට විතරක් add කළා නම් සහ remove කරන්න ඕන නම් run කරන්න:

    kubectl label node <node-name> workload-

## Important note

මෙය beginner lab එකක්.

මෙම lab එක existing shared Gateway එකක් හරහා external HTTP routing පෙන්වන්න Gateway API use කරනවා.

Shared Gateway හෝ Gateway controller resources delete කරන්න එපා, ඒවා ඔයා create කරලා තියෙනවා සහ වෙන දෙයක් use නොකරන බව දන්නවා නම් විතරක් delete කරන්න.
