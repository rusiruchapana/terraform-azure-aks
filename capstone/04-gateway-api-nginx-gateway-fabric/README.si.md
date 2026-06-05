# Stage 04 - Gateway API and NGINX Gateway Fabric

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී AKS platform එකට traffic entry layer එක install කරනවා.

අපි Gateway API CRDs install කරනවා.

ඊට පස්සේ NGINX Gateway Fabric install කරනවා.

අවසානයේ platform-level Gateway එකක් create කරනවා.

මෙම stage එකේදී application route එකක් create කරන්නේ නැහැ. App route එක capstone app deployment stage එකේදී HTTPRoute එකක් විදිහට add කරනවා.

## Gateway API කියන්නේ මොකක්ද?

Gateway API කියන්නේ Kubernetes වල traffic routing define කරන්න තියෙන modern standard එකක්.

ඒක Ingress වලට වඩා platform engineering වලට හොඳ model එකක්.

Gateway API resources:

- GatewayClass
- Gateway
- HTTPRoute
- ReferenceGrant

සරලව:

Gateway API කියන්නේ traffic routing rules ලියන Kubernetes API එක.

## NGINX Gateway Fabric කියන්නේ මොකක්ද?

NGINX Gateway Fabric කියන්නේ Gateway API rules ක්‍රියාත්මක කරන controller එක.

Gateway API එක rules define කරනවා.

NGINX Gateway Fabric ඒ rules කියවලා actual NGINX proxy/data plane config කරලා traffic route කරනවා.

සරල analogy එක:

Gateway API = traffic rules book

NGINX Gateway Fabric = ඒ rules follow කරලා traffic direct කරන traffic controller

## Gateway API සහ NGINX Gateway Fabric දෙකම ඕන ඇයි?

Gateway API තනියම traffic route කරන්නේ නැහැ.

ඒක Kubernetes resources define කරන standard එකක්.

NGINX Gateway Fabric තනියම routing rules නැතුව වැඩ කරන්නේ නැහැ.

ඒක Gateway API resources watch කරලා routing implement කරනවා.

ඒ නිසා දෙකම එකට ඕන.

## Architecture flow

User request එක app එකට යන්නේ මෙහෙමයි:

Internet
→ Azure Load Balancer
→ NGINX Gateway Fabric service
→ Platform Gateway
→ HTTPRoute
→ Kubernetes Service
→ App Pods

මෙම stage එකෙන් create වෙන කොටස:

Internet
→ Azure Load Balancer
→ NGINX Gateway Fabric
→ Platform Gateway

HTTPRoute සහ App Service පස්සේ create කරනවා.

## Platform team vs app team responsibility

Gateway API හොඳයි මොකද responsibility separation එක clear වෙනවා.

Platform team:

- GatewayClass manage කරනවා
- shared Gateway create කරනවා
- listeners, TLS, shared policies manage කරනවා

Application team:

- HTTPRoute create කරනවා
- app path/host routing define කරනවා
- app service backend define කරනවා

මෙම project එකේ `platform-gateway` namespace එක platform-owned area එකක්.

## Commands used in this stage

Gateway API CRDs install කිරීම:

    kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard" | kubectl apply -f -

NGINX Gateway Fabric install කිරීම:

    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
      --create-namespace \
      -n nginx-gateway \
      --wait

Verify කිරීම:

    kubectl get all -n nginx-gateway
    kubectl get gatewayclass
    kubectl get svc -n nginx-gateway

Platform Gateway create කිරීම:

    kubectl apply -f platform/gateway/platform-gateway.yaml

Gateway verify කිරීම:

    kubectl get gateway -n platform-gateway
    kubectl describe gateway platform-gateway -n platform-gateway

## platform-gateway.yaml

මෙම manifest එක namespace එකක් සහ Gateway එකක් create කරනවා.

GatewayClass:

    nginx

Listener:

    HTTP port 80

Allowed routes:

    all namespaces

මෙයින් capstone-dev, capstone-qa, capstone-prod namespaces වල app routes පස්සේ attach කරන්න පුළුවන්.

## Expected result

NGINX Gateway Fabric pods Running විය යුතුයි.

GatewayClass එක available විය යුතුයි.

platform-gateway Gateway එක Accepted/Programmed විය යුතුයි.

nginx-gateway service එක LoadBalancer type එකක් නම් Azure external IP එකක් assign විය හැක.

## Troubleshooting

### GatewayClass නැත්නම්

Check:

    kubectl get gatewayclass

NGINX Gateway Fabric install එක healthyද බලන්න:

    kubectl get pods -n nginx-gateway

### Gateway Pending නම්

Check:

    kubectl describe gateway platform-gateway -n platform-gateway

Check controller logs:

    kubectl logs -n nginx-gateway deploy/ngf-nginx-gateway-fabric

### External IP pending නම්

AKS LoadBalancer service එක external IP assign කරන්න ටික වෙලාවක් යන්න පුළුවන්.

Check:

    kubectl get svc -n nginx-gateway -w

## Production meaning

Production Kubernetes platform එකක apps direct LoadBalancer services වලින් expose කරන එක messy වෙනවා.

Shared Gateway එකක් දාගත්තොත්:

- central traffic entry point එකක් තියෙනවා
- app teams HTTPRoute වලින් තමන්ගේ app routing manage කරනවා
- platform team TLS/security/listeners/policies manage කරනවා
- routing model එක consistent වෙනවා

මෙය platform engineering mindset එකට හොඳ design එකක්.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Gateway API කියන්නේ routing standard එක.

NGINX Gateway Fabric කියන්නේ ඒ standard එක implement කරන controller එක.

Gateway කියන්නේ shared platform entry point එක.

HTTPRoute කියන්නේ app-specific routing rule එක.

මෙම stage එකෙන් traffic layer foundation එක ready වෙනවා.

## Issue checked during this stage

NGINX Gateway Fabric install කළාට පස්සේ `nginx-gateway` namespace එකේ service එක `ClusterIP` ලෙස පෙනුණා.

මුලින් ඒක external traffic path එක missing වගේ පෙනුණා.

නමුත් NGINX Gateway Fabric model එකේ controller service එක ClusterIP වීම normal.

Gateway API model එකේ external address එක Gateway resource එක create වුණාම assign වෙනවා.

මෙම command එකෙන් Gateway එක verify කළා:

    kubectl get gateway -n platform-gateway -o wide

Result එකේ `ADDRESS` value එක තිබුණා:

    20.53.203.159

Gateway status:

    Accepted=True
    Programmed=True

Listener status:

    Accepted=True
    Programmed=True
    ResolvedRefs=True
    Conflicted=False

ඒ කියන්නේ Gateway layer එක traffic receive කරන්න ready.

## Important verification lesson

Gateway controller pod Running කියලා විතරක් ප්‍රමාණවත් නැහැ.

Gateway layer verify කරනකොට මේවා බලන්න ඕන:

- Gateway API CRDs installed ද?
- NGINX Gateway Fabric pod Running ද?
- GatewayClass Accepted ද?
- Gateway resource Programmed ද?
- Gateway ADDRESS assign වෙලාද?
- Listener Accepted/Programmed ද?
- Conflicted=False ද?

## Why the controller service is ClusterIP

`ngf-nginx-gateway-fabric` service එක ClusterIP වුණාට ඒක issue එකක් නෙවෙයි.

ඒ service එක controller/agent internal communication සඳහා use වෙනවා.

Actual application traffic path එක Gateway resource එක හරහා expose වෙනවා.

මෙම project එකේ external Gateway address:

    20.53.203.159

පස්සේ capstone app එක deploy කළාම HTTPRoute එකක් create කරලා app traffic මේ Gateway හරහා route කරනවා.

## Issue checked during this stage

NGINX Gateway Fabric install කළාට පස්සේ `nginx-gateway` namespace එකේ service එක `ClusterIP` ලෙස පෙනුණා.

මුලින් ඒක external traffic path එක missing වගේ පෙනුණා.

නමුත් NGINX Gateway Fabric model එකේ controller service එක ClusterIP වීම normal.

Gateway API model එකේ external address එක Gateway resource එක create වුණාම assign වෙනවා.

මෙම command එකෙන් Gateway එක verify කළා:

    kubectl get gateway -n platform-gateway -o wide

Result එකේ `ADDRESS` value එක තිබුණා:

    20.53.203.159

Gateway status:

    Accepted=True
    Programmed=True

Listener status:

    Accepted=True
    Programmed=True
    ResolvedRefs=True
    Conflicted=False

ඒ කියන්නේ Gateway layer එක traffic receive කරන්න ready.

## Important verification lesson

Gateway controller pod Running කියලා විතරක් ප්‍රමාණවත් නැහැ.

Gateway layer verify කරනකොට මේවා බලන්න ඕන:

- Gateway API CRDs installed ද?
- NGINX Gateway Fabric pod Running ද?
- GatewayClass Accepted ද?
- Gateway resource Programmed ද?
- Gateway ADDRESS assign වෙලාද?
- Listener Accepted/Programmed ද?
- Conflicted=False ද?

## Why the controller service is ClusterIP

`ngf-nginx-gateway-fabric` service එක ClusterIP වුණාට ඒක issue එකක් නෙවෙයි.

ඒ service එක controller/agent internal communication සඳහා use වෙනවා.

Actual application traffic path එක Gateway resource එක හරහා expose වෙනවා.

මෙම project එකේ external Gateway address:

    20.53.203.159

පස්සේ capstone app එක deploy කළාම HTTPRoute එකක් create කරලා app traffic මේ Gateway හරහා route කරනවා.
