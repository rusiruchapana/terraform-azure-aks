# Beginner Lab 05 - Basic Kubernetes Troubleshooting

මෙම lab එකෙන් beginner Kubernetes troubleshooting scenarios කිහිපයක් practice කරනවා.

මෙය standalone beginner lab එකක්.

මෙම lab එක intentionally broken Kubernetes resources create කරනවා.

ඔයාගේ වැඩේ තමයි problem එක inspect කරලා, error එක තේරුම් අරගෙන, fix කරන එක.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේ common Kubernetes issues troubleshoot කරන්න පුළුවන් විය යුතුයි:

- `ImagePullBackOff`
- Service selector mismatch
- Wrong Service `targetPort`

ඔයාට මේ commands confidence එකෙන් use කරන්නත් පුළුවන් විය යුතුයි:

- `kubectl get`
- `kubectl describe`
- `kubectl logs`
- `kubectl get endpoints`
- `kubectl get pods --show-labels`
- `kubectl port-forward`

## Learning approach

Solution එක මුලින් open කරන්න එපා.

Recommended flow එක:

1. Broken manifest එක apply කරන්න
2. Error හෝ wrong behavior එක observe කරන්න
3. `kubectl get`, `kubectl describe`, `kubectl logs`, සහ `kubectl get endpoints` use කරන්න
4. Problem එක identify කරන්න try කරන්න
5. හිර වුණොත් විතරක් hint එක read කරන්න
6. Manifest එක ඔබම fix කරන්න
7. ඔයාගේ fix එක solution එක සමඟ compare කරන්න
8. Issue එක තේරුම් ගත්තට පස්සේ විතරක් solution apply කරන්න

Goal එක fixed YAML copy කරන එක නෙවෙයි.

Goal එක troubleshooting thinking pattern එක ඉගෙන ගන්න එක.

## Lab architecture

මෙම lab එක එක namespace එකක් use කරනවා:

    beginner-troubleshooting

Scenarios:

    Scenario 1
      |
      v
    ImagePullBackOff
      |
      v
    Invalid image tag

    Scenario 2
      |
      v
    Service selector mismatch
      |
      v
    Service has no endpoints

    Scenario 3
      |
      v
    Wrong container port
      |
      v
    Service points to the wrong targetPort

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- AKS cluster access
- Terminal එකක්
- Port-forward test එකට web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- Gateway API
- Persistent storage
- Custom container image එකක්

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

## Files in this lab

මෙම lab එකේ files:

    broken/
      Intentionally broken manifests

    hints/
      Full answers නැති troubleshooting hints

    solutions/
      Compare කරන්න fixed manifests

Files:

    broken/namespace.yaml
    broken/01-imagepullbackoff.yaml
    broken/02-service-selector-mismatch.yaml
    broken/03-wrong-container-port.yaml
    hints/01-imagepullbackoff.md
    hints/02-service-selector-mismatch.md
    hints/03-wrong-container-port.md
    solutions/01-imagepullbackoff-fixed.yaml
    solutions/02-service-selector-mismatch-fixed.yaml
    solutions/03-wrong-container-port-fixed.yaml

## Important node selector note

Broken සහ solution Deployments වල මේ node selector එක තියෙනවා:

    nodeSelector:
      workload: user

ඒ කියන්නේ pods schedule වෙන්නේ මේ label එක තියෙන nodes වලට විතරයි:

    workload=user

ඔයාගේ nodes වල ඒ label එක තියෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඔයාගේ cluster එකේ මේ label එක නැත්නම්, worker node එකකට label එක add කරන්න හෝ manifests වලින් `nodeSelector` remove කරන්න.

මෙම lab එකට node එකක් label කරන්න:

    kubectl get nodes

Node name එකක් තෝරලා run කරන්න:

    kubectl label node <node-name> workload=user --overwrite

## Create namespace

මෙම command එක repository root එකේ සිට run කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/namespace.yaml

Verify කරන්න:

    kubectl get namespace beginner-troubleshooting

## Scenario 1 - ImagePullBackOff

Broken manifest එක apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/01-imagepullbackoff.yaml

Pods check කරන්න:

    kubectl get pods -n beginner-troubleshooting

Pod inspect කරන්න:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

මේ questions answer කරන්න try කරන්න:

- Pod status එක මොකක්ද?
- Kubernetes pull කරන්න try කරන image එක මොකක්ද?
- Image tag එක exist වෙනවද?
- මේක authentication problem එකක්ද, image name/tag problem එකක්ද?

හිර වුණොත් read කරන්න:

    labs/beginner/05-basic-troubleshooting/hints/01-imagepullbackoff.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

Verify කරන්න:

    kubectl rollout status deployment/imagepull-demo -n beginner-troubleshooting --timeout=180s
    kubectl get pods -n beginner-troubleshooting

Expected:

    imagepull-demo pod Running වෙන්න ඕන.

## Scenario 2 - Service selector mismatch

Broken manifest එක apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/02-service-selector-mismatch.yaml

Pods සහ service check කරන්න:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Endpoints check කරන්න:

    kubectl get endpoints selector-demo -n beginner-troubleshooting

Labels inspect කරන්න:

    kubectl get pods -n beginner-troubleshooting --show-labels

Service inspect කරන්න:

    kubectl describe svc selector-demo -n beginner-troubleshooting

මේ questions answer කරන්න try කරන්න:

- Pod Running ද?
- Service එකට endpoints තියෙනවද?
- Pod එකේ labels මොනවද?
- Service selector එක මොකක්ද?
- Service selector එක pod labels match කරනවද?

හිර වුණොත් read කරන්න:

    labs/beginner/05-basic-troubleshooting/hints/02-service-selector-mismatch.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

Endpoints verify කරන්න:

    kubectl get endpoints selector-demo -n beginner-troubleshooting

Expected:

    selector-demo එකට අවම වශයෙන් endpoint එකක් තියෙන්න ඕන.

## Scenario 3 - Wrong container port

Broken manifest එක apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/03-wrong-container-port.yaml

Pods සහ service check කරන්න:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Service details check කරන්න:

    kubectl describe svc wrong-port-demo -n beginner-troubleshooting

Endpoints check කරන්න:

    kubectl get endpoints wrong-port-demo -n beginner-troubleshooting

Port-forward try කරන්න:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open කරන්න:

    http://localhost:8083

මේ questions answer කරන්න try කරන්න:

- Pod Running ද?
- Service එකට endpoints තියෙනවද?
- Service එක correct `targetPort` එකට point කරනවද?
- NGINX actually listen කරන port එක මොකක්ද?

හිර වුණොත් read කරන්න:

    labs/beginner/05-basic-troubleshooting/hints/03-wrong-container-port.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

නැවත port-forward try කරන්න:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open කරන්න:

    http://localhost:8083

Expected:

    Default NGINX welcome page එක පේන්න ඕන.

Port-forward stop කරන්න:

    Ctrl+C

## Useful troubleshooting commands

Pods list කරන්න:

    kubectl get pods -n beginner-troubleshooting

Labels සමඟ pods list කරන්න:

    kubectl get pods -n beginner-troubleshooting --show-labels

Pod describe කරන්න:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Pod logs බලන්න:

    kubectl logs -n beginner-troubleshooting <pod-name>

Services list කරන්න:

    kubectl get svc -n beginner-troubleshooting

Service describe කරන්න:

    kubectl describe svc <service-name> -n beginner-troubleshooting

Service endpoints බලන්න:

    kubectl get endpoints -n beginner-troubleshooting

Deployments check කරන්න:

    kubectl get deployment -n beginner-troubleshooting

Events check කරන්න:

    kubectl get events -n beginner-troubleshooting --sort-by=.lastTimestamp

## Troubleshooting tips

### ImagePullBackOff pattern

Use කරන්න:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

මෙය බලන්න:

    Events

Common cause:

    Wrong image name or image tag

### Service selector mismatch pattern

Use කරන්න:

    kubectl get endpoints -n beginner-troubleshooting
    kubectl get pods -n beginner-troubleshooting --show-labels
    kubectl describe svc <service-name> -n beginner-troubleshooting

Common cause:

    Service selector does not match pod labels

### Wrong targetPort pattern

Use කරන්න:

    kubectl describe svc <service-name> -n beginner-troubleshooting

Compare කරන්න:

    Service targetPort
    Container port
    Application listen port

Common cause:

    Service එක container එක listen නොකරන port එකකට traffic යවනවා

## Cleanup

Lab namespace එක delete කරන්න:

    kubectl delete namespace beginner-troubleshooting --ignore-not-found

මෙයින් මෙම lab එකෙන් create කළ resources සියල්ල remove වෙනවා.

`workload=user` label එක මෙම lab එකට විතරක් add කළා නම් සහ remove කරන්න ඕන නම් run කරන්න:

    kubectl label node <node-name> workload-

## Important note

මෙම lab එක intentionally broken resources create කරනවා.

Errors පේන එක expected.

Troubleshooting කියන්නේ commands memorize කරන එක නෙවෙයි.

Good troubleshooting flow එක:

    observe
      |
      v
    inspect
      |
      v
    identify root cause
      |
      v
    apply fix
      |
      v
    verify

Scenarios simple වුණත්, real Kubernetes issues වලටත් මේ same thinking pattern එක apply වෙනවා.
