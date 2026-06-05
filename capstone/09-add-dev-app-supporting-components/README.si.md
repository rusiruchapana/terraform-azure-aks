# Stage 09 - Dev App Supporting Components Add කිරීම

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Capstone Store dev application එකට supporting components තුනක් add කළා.

අලුතින් add කළ components:

    store-admin
    virtual-customer
    virtual-worker

මේ components තුන එකතු වුණාම app එක simple frontend/backend demo එකක් විතරක් නෙවෙයි. Production-style multi-component workload එකක් වගේ වෙනවා.

## මේ stage එක වැදගත් ඇයි?

Real-world application එකක් සාමාන්‍යයෙන් frontend එකක් සහ API එකක් විතරක් නෙවෙයි.

සාමාන්‍ය production app එකක මේ වගේ parts තියෙනවා:

    Customer UI
    Admin UI
    Backend APIs
    Database
    Message queue
    Background workers
    Traffic simulators
    Monitoring points

ඒ නිසා මේ stage එකෙන් learner ට තේරෙන්නේ application එක grow වෙනකොට Kubernetes platform එකට තවත් workloads, services, endpoints, scheduling, monitoring, and troubleshooting concerns add වෙනවා කියන එක.

## Stage 09 ට කලින් තිබුණ components

Stage 09 ට කලින් dev app එකේ තිබුණේ:

    store-front
    product-service
    order-service
    rabbitmq
    mongodb
    makeline-service

Stage 09 පස්සේ add වුණේ:

    store-admin
    virtual-customer
    virtual-worker

## store-admin කියන්නේ මොකක්ද?

store-admin කියන්නේ admin/operator UI එකක්.

සරලව:

    store-front  = customer-facing UI
    store-admin  = admin/operator UI

Production වලදී admin UI එක direct public internet එකට expose කරන එක risky. ඒ නිසා මේ project එකේ store-admin service එක ClusterIP ලෙස තබනවා.

## virtual-customer කියන්නේ මොකක්ද?

virtual-customer කියන්නේ fake customer traffic generate කරන component එකක්.

සරල flow එක:

    virtual-customer
        -> order-service
        -> rabbitmq
        -> makeline-service
        -> mongodb

Real users නැති learning environment එකක app activity generate කරන්න මේ component එක useful.

Monitoring, scaling, AIOps, incident simulation වගේ later stages වලට මේක වැදගත්.

## virtual-worker කියන්නේ මොකක්ද?

virtual-worker කියන්නේ background workload simulator එකක්.

Production examples:

    order processing
    email sending
    queue consuming
    report generation
    payment event handling
    batch jobs

මේ component එකෙන් learner ට background workers Kubernetes වල run වෙන විදිහ තේරෙනවා.

## GitOps repo changes

මේ stage එකේ changes කළේ GitOps repo එකේ.

Repo:

    aks-capstone-gitops

Path:

    apps/capstone-store/base

Added files:

    store-admin.yaml
    virtual-customer.yaml
    virtual-worker.yaml

Updated file:

    kustomization.yaml

## Images used

CI/CD and GitHub Actions part එකට තවම ආවේ නැහැ.

ඒ නිසා මේ stage එකේදී sample images use කළා:

    ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
    ghcr.io/azure-samples/aks-store-demo/virtual-customer:2.1.0
    ghcr.io/azure-samples/aks-store-demo/virtual-worker:2.1.0

දැනට flow එක:

    GitOps manifest update
        -> git commit and push
        -> Argo CD detects change
        -> Argo CD applies manifests
        -> Pods run in AKS

Future CI/CD flow එක:

    App source code change
        -> GitHub Actions build image
        -> Push image to ACR
        -> Update GitOps image tag
        -> Argo CD deploys to AKS

## kustomization.yaml update

kustomization.yaml file එකට new resources add කළා.

Expected resources:

    resources:
      - aks-store-quickstart.yaml
      - makeline-mongodb.yaml
      - store-admin.yaml
      - virtual-customer.yaml
      - virtual-worker.yaml

## Why ClusterIP instead of LoadBalancer?

Original sample manifest වල store-admin service එක LoadBalancer වෙන්න පුළුවන්.

නමුත් අපේ architecture එකේ public traffic control කරන්නේ Gateway API / NGINX Gateway Fabric එකෙන්.

Good pattern:

    Internet
        -> Gateway public IP
        -> HTTPRoute
        -> ClusterIP service
        -> Pod

Bad pattern for this project:

    Internet
        -> many LoadBalancer services
        -> many public IPs
        -> more cost and security risk

ඒ නිසා store-admin service එක ClusterIP ලෙස තබනවා.

Verify:

    kubectl get svc -n capstone-dev

Expected:

    store-admin   ClusterIP
    store-front   ClusterIP

## Namespace note

මෙම project එකේ dev app namespace එක:

    capstone-dev

Argo CD application name එක:

    capstone-store-dev

මේ දෙක same වෙන්න ඕන නැහැ.

මෙතන learner ට වැදගත් lesson එකක් තියෙනවා:

    Argo CD app name එක capstone-store-dev වුණත්
    Kubernetes namespace එක capstone-dev.

Wrong namespace check example:

    kubectl get pods -n capstone-store-dev

Correct namespace check:

    kubectl get pods -n capstone-dev

Argo CD destination namespace check කරන්න:

    kubectl get application capstone-store-dev -n argocd -o jsonpath='{.spec.destination.namespace}{"\n"}'

## Deploy verification

Pods check:

    kubectl get pods -n capstone-dev -o wide

Verified running components:

    makeline-service
    mongodb
    order-service
    product-service
    rabbitmq
    store-admin
    store-front
    virtual-customer
    virtual-worker

Services check:

    kubectl get svc -n capstone-dev

Expected services:

    makeline-service   ClusterIP
    mongodb            ClusterIP
    order-service      ClusterIP
    product-service    ClusterIP
    rabbitmq           ClusterIP
    store-admin        ClusterIP
    store-front        ClusterIP

## EndpointSlice verification

Kubernetes v1.33+ වලදී old Endpoints object වෙනුවට EndpointSlice use කිරීම recommended.

Check:

    kubectl get endpointslice -n capstone-dev

Verified EndpointSlices:

    makeline-service
    mongodb
    order-service
    product-service
    rabbitmq
    store-admin
    store-front

EndpointSlice තියෙනවා කියන්නේ Service එකට backing Pod endpoint එකක් තියෙනවා කියන එක.

Example:

    store-admin service
        -> 10.50.0.73:8081 pod endpoint

Service එක තියෙනවා, නමුත් EndpointSlice නැත්නම් traffic pod එකකට යන්නේ නැහැ.

## Gateway verification

HTTPRoute check:

    kubectl get httproute -A

Expected:

    capstone-dev   store-front

Gateway test:

    curl -I http://20.53.203.159

Expected:

    HTTP/1.1 200 OK

Important:

    Gateway public IP එකෙන් currently store-front expose වෙනවා.
    store-admin public expose කරලා නැහැ.

## Node placement observation

Stage 08 එකේ add කළ apps node pool එක Stage 09 වලදී useful වුණා.

Verified example:

    mongodb            -> aks-apps node
    store-admin        -> aks-apps node
    virtual-customer   -> aks-apps node
    virtual-worker     -> aks-apps node

මේකෙන් learner ට තේරෙන්නේ:

    New app components add කරනකොට extra node capacity අවශ්‍ය වෙනවා.
    Stage 08 capacity planning එක Stage 09 workload expansion එකට support කරනවා.

## Troubleshooting

### Issue 1 - Pods show no resources

Command:

    kubectl get pods -n capstone-store-dev

Output:

    No resources found

Possible reason:

    Wrong namespace.

Fix:

    kubectl get pods -A | grep -E 'store|rabbit|mongo|makeline|virtual|admin|product|order'
    kubectl get pods -n capstone-dev

### Issue 2 - ImagePullBackOff

Check:

    kubectl get pods -n capstone-dev
    kubectl describe pod -n capstone-dev <pod-name>

Possible reasons:

    Wrong image name
    Wrong image tag
    Registry access issue

Expected image pattern:

    ghcr.io/azure-samples/aks-store-demo/<component>:2.1.0

### Issue 3 - CrashLoopBackOff

Check logs:

    kubectl logs -n capstone-dev <pod-name>

Describe pod:

    kubectl describe pod -n capstone-dev <pod-name>

Possible reasons:

    Wrong environment variable
    Dependent service unavailable
    Application startup failure

### Issue 4 - Service has no endpoints

Check services:

    kubectl get svc -n capstone-dev

Check EndpointSlice:

    kubectl get endpointslice -n capstone-dev

Check labels:

    kubectl get pods -n capstone-dev --show-labels
    kubectl describe svc -n capstone-dev <service-name>

Possible reason:

    Service selector does not match pod labels.

### Issue 5 - Unexpected public IP created

Check services:

    kubectl get svc -n capstone-dev

If store-admin shows LoadBalancer, that means it may create another Azure public IP.

Fix manifest:

    spec:
      type: ClusterIP

Then commit and push GitOps repo.

### Issue 6 - Argo CD Synced but expected resources not visible

Check Argo CD destination namespace:

    kubectl get application capstone-store-dev -n argocd -o jsonpath='{.spec.destination.namespace}{"\n"}'

Check Argo CD source path:

    kubectl get application capstone-store-dev -n argocd -o jsonpath='{.spec.source.path}{"\n"}'

Check resources across all namespaces:

    kubectl get pods -A | grep -E 'store|rabbit|mongo|makeline|virtual|admin|product|order'

## Final verified state

Stage 09 final state:

    Namespace: capstone-dev

    Running pods:
      makeline-service
      mongodb
      order-service
      product-service
      rabbitmq
      store-admin
      store-front
      virtual-customer
      virtual-worker

    Services:
      All internal services are ClusterIP

    Gateway:
      Gateway public IP returns HTTP 200

    GitOps:
      capstone-store-dev Argo CD app is Synced / Healthy

## Learner summary

මේ stage එකේදී අපි app එක production-style workload එකකට expand කළා.

Key lesson:

    Simple demo app එකක් real platform learning වලට ප්‍රමාණවත් නෑ.

    Admin UI, background workers, simulated traffic, database, queue,
    service discovery, and Gateway routing එකට එකතු වුණාම
    real-world troubleshooting and CI/CD learning meaningful වෙනවා.

Stage 09 පස්සේ අපිට next stages වලට හොඳ base එකක් තියෙනවා:

    CI/CD with GitHub Actions
    ACR image build and push
    GitOps image tag updates
    Monitoring and alerting
    DevSecOps checks
    AIOps incident scenarios
