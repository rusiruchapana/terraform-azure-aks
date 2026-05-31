# Gateway API

This document explains how Gateway API and NGINX Gateway Fabric are used in this AKS DevOps Practice Platform.

## What is Gateway API?

Gateway API is the modern Kubernetes networking API for routing traffic into services.

It is designed to be more expressive and flexible than the older Ingress API.

This project uses Gateway API as the main application routing layer.

## Why Gateway API?

Gateway API provides a cleaner separation between platform teams and application teams.

Platform team responsibilities:

- Install Gateway API CRDs
- Install a Gateway controller
- Create shared Gateways
- Manage external LoadBalancers
- Manage platform-level routing policy

Application team responsibilities:

- Create Services
- Create HTTPRoutes
- Attach HTTPRoutes to the shared Gateway

## Why not create one LoadBalancer per app?

Creating one LoadBalancer per app can be expensive and hard to manage.

Instead, this platform uses one shared Gateway.

Apps attach routes to the shared Gateway.

High-level pattern:

    Internet
        |
        v
    Shared Gateway
        |
        v
    HTTPRoute
        |
        v
    Kubernetes Service
        |
        v
    Application Pods

## Components used

This platform uses:

- Gateway API CRDs
- NGINX Gateway Fabric
- GatewayClass named nginx
- Namespace named nginx-gateway
- Namespace named platform-gateway
- Shared Gateway named public-gateway

## Current shared Gateway

The shared Gateway is:

    platform-gateway/public-gateway

Applications should attach HTTPRoute resources to this Gateway.

## Install Gateway API CRDs

Gateway API CRDs are installed with kubectl.

Command used:

    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

Verify:

    kubectl api-resources | grep gateway
    kubectl get crd | grep gateway

Expected resources include:

    gatewayclasses
    gateways
    httproutes
    grpcroutes
    referencegrants

## Install NGINX Gateway Fabric

NGINX Gateway Fabric is installed with Helm.

Command used:

    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
      --namespace nginx-gateway \
      --create-namespace \
      --wait

Verify:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass

Expected:

    GatewayClass nginx accepted True

## Create platform Gateway namespace

Create the platform Gateway namespace:

    kubectl create namespace platform-gateway

## Create shared public Gateway

The shared Gateway is created in the platform-gateway namespace.

Gateway name:

    public-gateway

GatewayClass:

    nginx

Expected result:

    public-gateway gets an external LoadBalancer IP

Verify:

    kubectl get gateway -n platform-gateway
    kubectl get svc -n platform-gateway

Expected:

    public-gateway   nginx   <external-ip>   True

## Example shared Gateway manifest

Example:

    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: public-gateway
      namespace: platform-gateway
    spec:
      gatewayClassName: nginx
      listeners:
        - name: http
          protocol: HTTP
          port: 80
          allowedRoutes:
            namespaces:
              from: All

## Application routing pattern

Applications should create HTTPRoute resources in their own namespace.

The HTTPRoute should reference:

    platform-gateway/public-gateway

Example:

    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: my-app-route
      namespace: my-app
    spec:
      parentRefs:
        - name: public-gateway
          namespace: platform-gateway
      rules:
        - backendRefs:
            - name: my-app-service
              port: 80

## Application requirements

For an app to route through Gateway API, the app needs:

- Deployment
- Service
- HTTPRoute

The Service name and port in HTTPRoute must match the real Kubernetes Service.

## Verify Gateway health

Run:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl get gateway -n platform-gateway
    kubectl get svc -n platform-gateway

Healthy expected state:

    NGINX Gateway Fabric pod Running
    GatewayClass nginx Accepted=True
    public-gateway Programmed=True
    LoadBalancer external IP exists

## Verify HTTPRoutes

List all HTTPRoutes:

    kubectl get httproute -A

Describe a route:

    kubectl describe httproute <route-name> -n <namespace>

Check backend service:

    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>

## Common routing issues

### Gateway has no external IP

Possible causes:

- Azure LoadBalancer is still provisioning
- Cloud provider issue
- Service not created
- Quota or public IP issue

Check:

    kubectl get svc -n platform-gateway
    kubectl describe gateway public-gateway -n platform-gateway

### HTTPRoute is not working

Possible causes:

- Wrong parentRef
- Wrong Gateway namespace
- Wrong Service name
- Wrong Service port
- App pods are not Ready
- Service has no endpoints

Check:

    kubectl describe httproute <route-name> -n <namespace>
    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>
    kubectl get pods -n <namespace>

### GatewayClass not accepted

Possible causes:

- NGINX Gateway Fabric is not running
- Gateway controller failed
- CRDs are missing or mismatched

Check:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl describe gatewayclass nginx

## Cleanup guidance

Do not delete these platform components unless you want to remove the Gateway API layer:

- nginx-gateway namespace
- platform-gateway namespace
- public-gateway
- Gateway API CRDs
- NGINX Gateway Fabric

Safe cleanup for demo apps:

- Delete demo application namespace
- Delete demo Deployment
- Delete demo Service
- Delete demo HTTPRoute

Do not delete the shared platform Gateway during normal app cleanup.

## Current project note

In the current project, Gateway API and NGINX Gateway Fabric were installed manually during the platform build.

This is acceptable for the learning platform.

Future improvement:

- Move Gateway manifests into platform-addons
- Or manage Gateway API through GitOps
- Add optional TLS and hostname examples
- Add secure Grafana exposure lab using Gateway API

## Production-style recommendations

For production-style use, consider:

- HTTPS listener
- TLS certificates
- Hostname-based routing
- Separate routes per app
- Authentication where needed
- WAF or policy integration
- Rate limiting where supported
- GitOps-managed Gateway resources
