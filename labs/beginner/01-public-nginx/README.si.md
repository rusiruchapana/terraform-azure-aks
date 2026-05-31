# Beginner Lab 01 - Deploy Public NGINX Image

මෙම lab එකෙන් public Docker Hub image එකක් AKS cluster එකට deploy කරන විදිය ඉගෙන ගන්නවා.

මෙය පළමු beginner lab එකයි.

මෙම lab එකේදී Gateway API තවම use කරන්නේ නැහැ.

Application එක local machine එකෙන් access කරන්න `kubectl port-forward` use කරනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Kubernetes namespace එකක් create කරන විදිය
- Public Docker Hub image එකක් deploy කරන විදිය
- Kubernetes Service එකක් create කරන විදිය
- Pods සහ Services verify කරන විදිය
- Port-forward use කරලා app එක access කරන විදිය
- Lab resources safely cleanup කරන විදිය

## What this lab uses

මෙම lab එක use කරන්නේ:

- AKS
- Public Docker Hub image
- Kubernetes Namespace
- Kubernetes Deployment
- Kubernetes Service
- `kubectl port-forward`

## Prerequisites

Start කරන්න කලින් AKS cluster එක running ද බලන්න:

    kubectl get nodes

Expected:

    STATUS   Ready

Node status එක Ready නම් cluster එක commands accept කරන්න ready.

## Deploy the lab

Repository root එකෙන් namespace එක මුලින් apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/namespace.yaml

ඊට පස්සේ app resources apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/service.yaml

මෙතන namespace එක මුලින් apply කරනවා, මොකද Deployment සහ Service දෙකම ඒ namespace එක ඇතුළේ create වෙන නිසා.

## Verify resources

Pods check කරන්න:

    kubectl get pods -n beginner-nginx

Service check කරන්න:

    kubectl get svc -n beginner-nginx

Expected:

    Pod should be Running
    Service should be ClusterIP

Pod එක Running නම් container එක start වෙලා තියෙනවා. Service එක ClusterIP නම් cluster එක ඇතුළේ stable service endpoint එකක් create වෙලා තියෙනවා.

## Access the app locally

Port-forward use කරන්න:

    kubectl port-forward svc/nginx -n beginner-nginx 8080:80

Browser එකෙන් open කරන්න:

    http://localhost:8080

Default NGINX welcome page එක පේන්න ඕන.

Port-forward command එක run වෙලා තියෙන terminal එක close කළොත් local access stop වෙනවා.

## Troubleshooting

App එක load වෙන්නේ නැත්නම්, pod එක check කරන්න:

    kubectl get pods -n beginner-nginx
    kubectl describe pod -n beginner-nginx <pod-name>

Service එක check කරන්න:

    kubectl get svc -n beginner-nginx

Service endpoints check කරන්න:

    kubectl get endpoints -n beginner-nginx

Common issues:

- Pod is not Running
- Image cannot be pulled
- Service selector does not match pod labels
- Port-forward command is not running
- Local port 8080 is already in use

මෙම troubleshooting commands වලින් pod status, events, service, සහ endpoints check කරලා root cause එක හොයාගන්න පුළුවන්.

## Cleanup

Lab resources delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/service.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/deployment.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/01-public-nginx/manifests/namespace.yaml

මෙයින් මෙම lab එකේ resources විතරක් remove වෙනවා.
