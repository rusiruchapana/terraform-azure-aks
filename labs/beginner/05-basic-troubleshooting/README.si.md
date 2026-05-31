# Beginner Lab 05 - Basic Kubernetes Troubleshooting

මෙම lab එකෙන් Kubernetes වල common problems තුනක් intentionally break කරලා, ඒවා troubleshoot කරලා fix කරන විදිය ඉගෙන ගන්නවා.

මෙය beginner labs වල ඉතා වැදගත් lab එකක්. Kubernetes ඉගෙන ගන්නකොට errors එන එක normal. වැදගත් දේ error එකක් ආවම panic නොවී, correct commands use කරලා root cause එක හොයාගන්න එක.

## Learning approach

මෙම lab එකේ approach එක:

1. Broken manifest එක apply කරනවා
2. Error / wrong behavior එක observe කරනවා
3. `kubectl get`, `kubectl describe`, `kubectl logs`, සහ `kubectl get endpoints` use කරනවා
4. Root cause එක හඳුනාගන්නවා
5. Fixed manifest එක apply කරනවා
6. Result එක verify කරනවා

මෙම lab එකේ goal එක “fixed YAML copy paste” කිරීම නෙවෙයි. Goal එක troubleshooting thinking pattern එක ඉගෙන ගන්න එක.

## Folder structure

මෙම lab එකේ files structure එක:

    broken/
      intentionally broken manifests

    hints/
      guided troubleshooting hints

    solutions/
      fixed manifests

Broken manifests වලින් error recreate කරනවා. Solutions folder එකේ same scenario එකට fix කරපු manifests තියෙනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- `kubectl get` use කරලා resources status බලන විදිය
- `kubectl describe` use කරලා event/error details බලන විදිය
- `kubectl logs` use කරලා app logs බලන විදිය
- `kubectl get endpoints` use කරලා Service backend connection බලන විදිය
- ImagePullBackOff troubleshoot කරන විදිය
- Service selector mismatch troubleshoot කරන විදිය
- Wrong container port issue troubleshoot කරන විදිය

## Create namespace

Repository root එකෙන් namespace එක create කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/namespace.yaml

## Scenario 1 - ImagePullBackOff

Broken manifest එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/01-imagepullbackoff.yaml

Pods check කරන්න:

    kubectl get pods -n beginner-troubleshooting

Pod inspect කරන්න:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

මේ questions ටික answer කරන්න try කරන්න:

- Pod status එක මොකක්ද?
- Kubernetes pull කරන්න try කරන image එක මොකක්ද?
- Image tag එක exist වෙනවද?
- මේක authentication problem එකක්ද, නැත්නම් image name/tag problem එකක්ද?

හිර වුණොත් read කරන්න:

    hints/01-imagepullbackoff.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    solutions/01-imagepullbackoff-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

## Scenario 2 - Service selector mismatch

Broken manifest එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/02-service-selector-mismatch.yaml

Pods සහ service check කරන්න:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Endpoints check කරන්න:

    kubectl get endpoints -n beginner-troubleshooting

Labels inspect කරන්න:

    kubectl get pods -n beginner-troubleshooting --show-labels

මේ questions ටික answer කරන්න try කරන්න:

- Pod Running ද?
- Service එකට endpoints තියෙනවද?
- Service selector එක pod labels match කරනවද?

හිර වුණොත් read කරන්න:

    hints/02-service-selector-mismatch.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    solutions/02-service-selector-mismatch-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

## Scenario 3 - Wrong container port

Broken manifest එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/03-wrong-container-port.yaml

Pods සහ service check කරන්න:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Service details check කරන්න:

    kubectl describe svc wrong-port-demo -n beginner-troubleshooting

Port-forward try කරන්න:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open කරන්න:

    http://localhost:8083

මේ questions ටික answer කරන්න try කරන්න:

- Pod Running ද?
- Service එක correct targetPort එකට point කරනවද?
- NGINX actually listen කරන port එක මොකක්ද?

හිර වුණොත් read කරන්න:

    hints/03-wrong-container-port.md

ඔබම fix එකක් try කළාට පස්සේ compare කරන්න:

    solutions/03-wrong-container-port-fixed.yaml

Fix එක attempt කළාට පස්සේ විතරක් solution apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

## Useful troubleshooting commands

Pods list කරන්න:

    kubectl get pods -n beginner-troubleshooting

Pod details බලන්න:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Pod logs බලන්න:

    kubectl logs -n beginner-troubleshooting <pod-name>

Services බලන්න:

    kubectl get svc -n beginner-troubleshooting

Endpoints බලන්න:

    kubectl get endpoints -n beginner-troubleshooting

Pod labels බලන්න:

    kubectl get pods -n beginner-troubleshooting --show-labels

මෙම commands Kubernetes troubleshooting වල basic toolkit එක.

## Cleanup

Lab namespace එක delete කරන්න:

    kubectl delete namespace beginner-troubleshooting

## Important note

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

මෙම lab එකේ scenarios simple වුණත්, production Kubernetes issues වලටත් මේ same thinking pattern එක apply වෙනවා.
