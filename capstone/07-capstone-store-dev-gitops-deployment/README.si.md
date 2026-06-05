# Stage 07 - Capstone Store Dev GitOps Deployment

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී Capstone Store application එක පළමු වතාවට AKS cluster එකට deploy කරනවා.

Deploy කරන්නේ manual `kubectl apply` වලින් නෙවෙයි.

Deploy කරන්නේ GitOps repo එක හරහා Argo CD use කරලා.

මෙම stage එකේ target environment එක:

    capstone-dev

## මේ stage එකේ final result එක

මෙම stage එක අවසානයේදී:

- capstone-store-dev Argo CD Application එක Synced / Healthy වෙනවා
- store-front, product-service, order-service, rabbitmq pods Running වෙනවා
- app services ClusterIP ලෙස internal විදිහට expose වෙනවා
- HTTPRoute එක platform Gateway එකට attach වෙනවා
- external traffic platform-gateway හරහා app එකට යනවා
- browser/curl වලින් app එක HTTP 200 OK return කරනවා

## App repo සහ GitOps repo separation

මෙම capstone එකේ repos දෙකක් app deployment සඳහා use වෙනවා.

### Application source repo

    aks-capstone-store-app

මෙහි තියෙන්නේ:

- source code
- Dockerfiles
- original sample manifests
- CI/CD pipeline files later

### GitOps repo

    aks-capstone-gitops

මෙහි තියෙන්නේ:

- Kubernetes manifests
- Kustomize base
- dev / qa / prod overlays
- Argo CD Applications
- HTTPRoute definitions

Production mindset එක:

Application source code repo එකේ app code තියෙනවා.

GitOps repo එකේ cluster desired state තියෙනවා.

Terraform/platform repo එකේ infrastructure සහ guides තියෙනවා.

## ඇයි මුලින් lighter version එක deploy කළේ?

Full app එකේ services ගොඩක් තියෙනවා:

- mongodb
- rabbitmq
- order-service
- makeline-service
- product-service
- store-front
- store-admin
- virtual-customer
- virtual-worker
- ai-service

නමුත් මුලින් අපි lighter working slice එක deploy කළා:

- rabbitmq
- order-service
- product-service
- store-front

මේක project එක අඩු කරන එකක් නෙවෙයි.

මේක professional rollout strategy එකක්.

මුලින් prove කරන්න ඕන:

GitOps repo
→ Argo CD
→ capstone-dev namespace
→ pods
→ services
→ HTTPRoute
→ platform Gateway
→ HTTP 200 OK

මෙම path එක stable වුණාට පස්සේ full app components add කරන්න පුළුවන්.

## GitOps deployment flow

මෙම stage එකේ flow එක:

aks-capstone-store-app repo එකෙන් quickstart manifest එක ගන්නවා
→ aks-capstone-gitops repo එකේ base folder එකට copy කරනවා
→ dev overlay එක create කරනවා
→ HTTPRoute එක add කරනවා
→ Argo CD Application එක create කරනවා
→ Argo CD Git state එක cluster එකට sync කරනවා

## GitOps repo structure

මෙම stage එකේදී GitOps repo එකේ relevant structure එක:

    apps/capstone-store/
      base/
        aks-store-quickstart.yaml
        kustomization.yaml

      overlays/
        dev/
          kustomization.yaml
          httproute-store-front.yaml
          patch-store-front-service.yaml

    argocd/
      applications/
        capstone-store-dev.yaml

## Base manifest

Base manifest එක original app repo එකෙන් copy කළා:

    aks-store-quickstart.yaml

මෙහි resources:

- rabbitmq ConfigMap
- rabbitmq StatefulSet
- rabbitmq Service
- order-service Deployment
- order-service Service
- product-service Deployment
- product-service Service
- store-front Deployment
- store-front Service

## Dev overlay

Dev overlay එකෙන් resources capstone-dev namespace එකට deploy වෙනවා.

Dev overlay එකට app labels add කරනවා:

    app.kubernetes.io/part-of: capstone-store
    environment: dev

මෙම labels debugging, filtering, monitoring, and future AIOps evidence collection සඳහා useful.

## HTTPRoute

Application එක expose කරන්නේ direct LoadBalancer service එකකින් නෙවෙයි.

Expose කරන්නේ Gateway API හරහා.

Flow:

Internet
→ platform-gateway
→ HTTPRoute
→ store-front Service
→ store-front Pod

HTTPRoute එක:

    parentRefs:
      - name: platform-gateway
        namespace: platform-gateway

    backendRefs:
      - name: store-front
        port: 80

## Store-front Service ClusterIP fix

Original quickstart manifest එකේ store-front service එක LoadBalancer ලෙස තිබුණා.

නමුත් අපේ platform design එකේ app services direct public LoadBalancer වෙන්න හොඳ නැහැ.

Production-style model එක:

- Only shared platform Gateway public expose වෙනවා
- App services internal ClusterIP ලෙස තියෙනවා
- Routing HTTPRoute වලින් manage වෙනවා

ඒ නිසා dev overlay එකේ patch එකක් add කළා:

    apiVersion: v1
    kind: Service
    metadata:
      name: store-front
    spec:
      type: ClusterIP

Final result:

    service/store-front   ClusterIP

## Important issue: immutable selector problem

මෙම stage එකේදී Argo CD OutOfSync issue එකක් ආවා.

Error එක:

    Deployment.apps is invalid:
    spec.selector: Invalid value: field is immutable

Meaning:

Kubernetes වල Deployment selector create කළාට පස්සේ change කරන්න බැහැ.

Kustomize labels change එක නිසා desired selector shape එක live resource selector shape එකෙන් වෙනස් වුණා.

ඒ නිසා Argo CD patch කරන්න ගියවිට fail වුණා.

## Immutable selector fix

Fix එක ලෙස dev kustomization එකේ labels transformer එක update කළා:

    labels:
      - includeSelectors: true
        includeTemplates: true
        pairs:
          app.kubernetes.io/part-of: capstone-store
          environment: dev

මේකෙන් labels pod templates වලටත් selectors වලටත් consistent ලෙස apply වෙනවා.

Final result:

    capstone-store-dev = Synced / Healthy

## Commands used in this stage

Quickstart manifest copy කිරීම:

    cp /Users/andrewferdinandus/projcts/aks-capstone-store-app/aks-store-quickstart.yaml \
      apps/capstone-store/base/aks-store-quickstart.yaml

Base kustomization:

    resources:
      - aks-store-quickstart.yaml

Dev overlay:

    namespace: capstone-dev

    resources:
      - ../../base
      - httproute-store-front.yaml

    labels:
      - includeSelectors: true
        includeTemplates: true
        pairs:
          app.kubernetes.io/part-of: capstone-store
          environment: dev

    patches:
      - path: patch-store-front-service.yaml

Argo CD Application apply කිරීම:

    kubectl apply -f argocd/applications/capstone-store-dev.yaml

Argo CD refresh/sync කිරීම:

    kubectl annotate application capstone-store-dev -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

    kubectl patch application capstone-store-dev -n argocd --type merge \
      -p '{"operation":{"sync":{"revision":"main"}}}'

## Verification commands

Argo CD Application status:

    kubectl get application capstone-store-dev -n argocd -o wide

Workloads:

    kubectl get all -n capstone-dev

HTTPRoute:

    kubectl get httproute -n capstone-dev
    kubectl describe httproute store-front -n capstone-dev

Gateway:

    kubectl get gateway -n platform-gateway -o wide

Gateway test:

    GATEWAY_IP="$(kubectl get gateway platform-gateway -n platform-gateway -o jsonpath='{.status.addresses[0].value}')"
    curl -I "http://$GATEWAY_IP"

## Expected result

Argo CD:

    capstone-store-dev   Synced   Healthy

Pods:

    order-service     1/1 Running
    product-service   1/1 Running
    rabbitmq          1/1 Running
    store-front       1/1 Running

Services:

    order-service     ClusterIP
    product-service   ClusterIP
    rabbitmq          ClusterIP
    store-front       ClusterIP

Gateway test:

    HTTP/1.1 200 OK

## Production meaning

මෙම stage එකෙන් app deployment flow එක real GitOps model එකට connect වුණා.

මෙතනින් පස්සේ application changes manual kubectl apply වලින් නෙවෙයි.

Correct flow එක:

Git change
→ commit
→ push
→ Argo CD sync
→ cluster update

App exposure model එකත් production-style:

Public traffic එක shared Gateway එකෙන් යනවා.

Application services internal ClusterIP ලෙස තියෙනවා.

## Troubleshooting lessons

### App Healthy but Argo CD OutOfSync

App එක වැඩ කළත් Argo CD OutOfSync නම් Git desired state සහ live state අතර mismatch එකක් තියෙනවා.

Check:

    kubectl describe application capstone-store-dev -n argocd

### Immutable selector error

Deployment selector or StatefulSet restricted fields change කරන්න බැහැ.

Labels/selectors change කරනකොට careful වෙන්න ඕන.

### Gateway 200 OK but Argo CD OutOfSync

Traffic path working වුණත් GitOps state clean නැත්නම් production ready කියන්න බැහැ.

Production වල app healthy + GitOps Synced දෙකම වැදගත්.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Application deploy කිරීම කියන්නේ pods Running කරන එක විතරක් නෙවෙයි.

Production-style deployment එකට මේවා ඔක්කොම හරි වෙන්න ඕන:

- GitOps source of truth
- Argo CD Synced / Healthy
- internal ClusterIP services
- Gateway-based external access
- clean labels/selectors
- repeatable environment overlay
- verified HTTP response
