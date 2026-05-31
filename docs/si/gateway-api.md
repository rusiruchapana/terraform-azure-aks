# Gateway API

මෙම document එකෙන් AKS DevOps Practice Platform එකේ Gateway API සහ NGINX Gateway Fabric use කරන ආකාරය පැහැදිලි කරනවා.

## Gateway API කියන්නේ මොකක්ද?

Gateway API කියන්නේ Kubernetes services වලට traffic route කරන්න use කරන modern Kubernetes networking API එකක්.

ඒක old Ingress API එකට වඩා expressive සහ flexible.

මෙම project එක application routing layer එක ලෙස Gateway API use කරනවා.

## Gateway API use කරන්නේ ඇයි?

Gateway API මගින් platform teams සහ application teams අතර clean separation එකක් ලැබෙනවා.

Platform team responsibilities:

- Gateway API CRDs install කිරීම
- Gateway controller install කිරීම
- Shared Gateways create කිරීම
- External LoadBalancers manage කිරීම
- Platform-level routing policy manage කිරීම

Application team responsibilities:

- Services create කිරීම
- HTTPRoutes create කිරීම
- Shared Gateway එකට HTTPRoutes attach කිරීම

## එක් app එකකට එක LoadBalancer එකක් create නොකරන්නේ ඇයි?

එක් app එකකට එක LoadBalancer එකක් create කළොත් cost වැඩි වෙනවා සහ manage කරන්න අමාරු වෙනවා.

ඒ වෙනුවට මෙම platform එක shared Gateway pattern එක use කරනවා.

Apps shared Gateway එකට routes attach කරනවා.

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

## Use කරන components

මෙම platform එක use කරන components:

- Gateway API CRDs
- NGINX Gateway Fabric
- nginx කියන GatewayClass
- nginx-gateway namespace
- platform-gateway namespace
- public-gateway කියන shared Gateway

## Current shared Gateway

Shared Gateway එක:

    platform-gateway/public-gateway

Applications HTTPRoute resources මේ Gateway එකට attach කරන්න ඕන.

## Gateway API CRDs install කිරීම

Gateway API CRDs kubectl මගින් install කරනවා.

Use කළ command එක:

    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

Verify කරන්න:

    kubectl api-resources | grep gateway
    kubectl get crd | grep gateway

Expected resources:

    gatewayclasses
    gateways
    httproutes
    grpcroutes
    referencegrants

## NGINX Gateway Fabric install කිරීම

NGINX Gateway Fabric Helm වලින් install කරනවා.

Use කළ command එක:

    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
      --namespace nginx-gateway \
      --create-namespace \
      --wait

Verify කරන්න:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass

Expected:

    GatewayClass nginx accepted True

## platform Gateway namespace create කිරීම

platform Gateway namespace එක create කරන්න:

    kubectl create namespace platform-gateway

## Shared public Gateway create කිරීම

Shared Gateway එක platform-gateway namespace එකේ create කරනවා.

Gateway name:

    public-gateway

GatewayClass:

    nginx

Expected result:

    public-gateway එකට external LoadBalancer IP එකක් ලැබෙනවා

Verify කරන්න:

    kubectl get gateway -n platform-gateway
    kubectl get svc -n platform-gateway

Expected:

    public-gateway   nginx   <external-ip>   True

## Shared Gateway manifest example

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

Applications තමන්ගේ namespace එකේ HTTPRoute resources create කරන්න ඕන.

HTTPRoute එක reference කරන්න ඕන:

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

Gateway API මගින් app එක route වෙන්න app එකට මේවා ඕන:

- Deployment
- Service
- HTTPRoute

HTTPRoute එකේ Service name සහ port real Kubernetes Service එකට match වෙන්න ඕන.

## Gateway health verify කිරීම

Run කරන්න:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl get gateway -n platform-gateway
    kubectl get svc -n platform-gateway

Healthy expected state:

    NGINX Gateway Fabric pod Running
    GatewayClass nginx Accepted=True
    public-gateway Programmed=True
    LoadBalancer external IP exists

## HTTPRoutes verify කිරීම

All HTTPRoutes list කරන්න:

    kubectl get httproute -A

Route එක describe කරන්න:

    kubectl describe httproute <route-name> -n <namespace>

Backend service check කරන්න:

    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>

## Common routing issues

### Gateway external IP එකක් නැහැ

Possible causes:

- Azure LoadBalancer තවම provisioning
- Cloud provider issue
- Service create වෙලා නැහැ
- Quota හෝ public IP issue

Check කරන්න:

    kubectl get svc -n platform-gateway
    kubectl describe gateway public-gateway -n platform-gateway

### HTTPRoute වැඩ කරන්නේ නැහැ

Possible causes:

- parentRef වැරදියි
- Gateway namespace වැරදියි
- Service name වැරදියි
- Service port වැරදියි
- App pods Ready නැහැ
- Service endpoints නැහැ

Check කරන්න:

    kubectl describe httproute <route-name> -n <namespace>
    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>
    kubectl get pods -n <namespace>

### GatewayClass accepted නැහැ

Possible causes:

- NGINX Gateway Fabric run වෙන්නේ නැහැ
- Gateway controller fail වෙලා
- CRDs missing හෝ mismatched

Check කරන්න:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl describe gatewayclass nginx

## Cleanup guidance

Gateway API layer එක remove කරන්න ඕන නැත්නම් මේ platform components delete කරන්න එපා:

- nginx-gateway namespace
- platform-gateway namespace
- public-gateway
- Gateway API CRDs
- NGINX Gateway Fabric

Demo apps cleanup කරන්න safe දේවල්:

- Demo application namespace delete කිරීම
- Demo Deployment delete කිරීම
- Demo Service delete කිරීම
- Demo HTTPRoute delete කිරීම

Normal app cleanup වලදී shared platform Gateway delete කරන්න එපා.

## Current project note

Current project එකේ Gateway API සහ NGINX Gateway Fabric manually install කළා.

Learning platform එකට මේක acceptable.

Future improvement:

- Gateway manifests platform-addons වලට move කිරීම
- නැත්නම් Gateway API GitOps මගින් manage කිරීම
- Optional TLS සහ hostname examples add කිරීම
- Gateway API use කරලා secure Grafana exposure lab add කිරීම

## Production-style recommendations

Production-style use සඳහා consider කරන්න:

- HTTPS listener
- TLS certificates
- Hostname-based routing
- App එකකට separate routes
- අවශ්‍ය තැන authentication
- WAF හෝ policy integration
- Supported නම් rate limiting
- GitOps-managed Gateway resources
