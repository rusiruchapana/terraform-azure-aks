# Beginner Lab 02 - Expose NGINX with Gateway API

මෙම lab එකෙන් NGINX application එක Gateway API හරහා expose කරන විදිය ඉගෙන ගන්නවා.

Lab 01 වල අපි Service එක port-forward කරලා local machine එකෙන් access කළා. මෙම lab එකේදී Gateway API use කරලා cluster එකට external HTTP routing එකක් configure කරනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Gateway API basic routing flow එක
- Existing Gateway එකක් use කරන විදිය
- HTTPRoute එකක් create කරන විදිය
- Service එකක් HTTPRoute එකට connect කරන විදිය
- Gateway external IP එකෙන් app එක access කරන විදිය
- Gateway / HTTPRoute troubleshooting කරන විදිය

## What this lab uses

මෙම lab එක use කරන්නේ:

- AKS cluster
- `kubectl`
- NGINX Deployment
- Kubernetes Service
- Gateway API
- Existing Gateway resource
- HTTPRoute

Lab manifests තියෙන්නේ:

    terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/

Files:

    namespace.yaml
    deployment.yaml
    service.yaml
    httproute.yaml

## Prerequisites

මෙම lab එකට පෙර මේවා ready වෙලා තියෙන්න ඕන:

- AKS cluster එක running වෙන්න ඕන
- `kubectl` current AKS cluster එකට connect වෙලා තියෙන්න ඕන
- Gateway API controller / NGINX Gateway Fabric install වෙලා තියෙන්න ඕන
- `platform-gateway` namespace එකේ `public-gateway` Gateway එක තියෙන්න ඕන

Check කරන්න:

    kubectl get nodes
    kubectl get pods -n nginx-gateway
    kubectl get gateway -n platform-gateway

Expected:

    Nodes Ready වෙන්න ඕන.
    Gateway controller pods Running වෙන්න ඕන.
    public-gateway Gateway එක Programmed=True වගේ healthy state එකක තියෙන්න ඕන.

## Deploy the lab

Namespace එක මුලින් apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/namespace.yaml

ඊට පස්සේ Deployment, Service, සහ HTTPRoute apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/service.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/httproute.yaml

මෙතන namespace එක වෙනම apply කරන එක safe. Namespace create වෙලා ඉවර වෙන්න කලින් Deployment/HTTPRoute apply වුණොත් `namespace not found` error එකක් එන්න පුළුවන්.

## Verify resources

Namespace එක verify කරන්න:

    kubectl get ns beginner-nginx

Pods බලන්න:

    kubectl get pods -n beginner-nginx

Service බලන්න:

    kubectl get svc -n beginner-nginx

HTTPRoute බලන්න:

    kubectl get httproute -n beginner-nginx

Gateway බලන්න:

    kubectl get gateway -n platform-gateway

Expected:

    nginx pod එක Running වෙන්න ඕන.
    nginx service එක තියෙන්න ඕන.
    nginx-route HTTPRoute එක පේන්න ඕන.
    public-gateway Gateway එක external ADDRESS එකක් සහ Programmed=True state එකක් පෙන්වන්න ඕන.

## Access the app

Gateway external IP එක බලන්න:

    kubectl get gateway public-gateway -n platform-gateway

Browser එකෙන් open කරන්න:

    http://<gateway-external-ip>

Expected page:

    Welcome to nginx!

මෙම page එක පේනවා නම් Gateway API route එක app එකට traffic forward කරනවා.

## Troubleshooting

App එක access වෙන්නේ නැත්නම්, මුලින් pod එක Running ද බලන්න:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Service endpoints check කරන්න:

    kubectl get endpoints -n beginner-nginx

Endpoints empty නම් Service selector එක Pod labels match කරන්නේ නැති වෙන්න පුළුවන්.

HTTPRoute check කරන්න:

    kubectl describe httproute nginx-route -n beginner-nginx

Common issues:

- Pod is not Running
- Service selector does not match pod labels
- HTTPRoute is not attached to the Gateway
- Gateway has no external address yet
- Wrong backend service name or port

මෙම commands වලින් pod, service endpoint, සහ route attachment status check කරලා issue එක හොයාගන්න පුළුවන්.

## Cleanup

Lab resources delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/02-nginx-gateway/manifests/

Namespace not found හෝ resources not found නම් cleanup complete.

