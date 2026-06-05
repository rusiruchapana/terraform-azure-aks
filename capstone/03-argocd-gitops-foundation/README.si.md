# Stage 03 - Argo CD GitOps Foundation

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී AKS cluster එකට Argo CD install කරනවා.

Argo CD කියන්නේ GitOps continuous delivery tool එකක්.

මෙම stage එකේදී application deploy කරන්නේ නැහැ. මුලින් GitOps engine එක cluster එකට install කරලා verify කරනවා.

## ඇයි Argo CD වැදගත්?

Production Kubernetes platform එකක resources manual kubectl apply වලින් change කරන එක risky.

Manual changes වල ප්‍රශ්න:

- කවුද change කළේ කියලා track කරන්න අමාරුයි
- rollback කරන්න අමාරුයි
- cluster state එක Git repo එකේ තියෙන desired state එකෙන් වෙනස් වෙන්න පුළුවන්
- approval process එකක් නැති වෙන්න පුළුවන්

Argo CD use කළාම:

- Git repo එක source of truth වෙනවා
- cluster desired state එක Git වල තියෙනවා
- Argo CD cluster එක Git state එකට sync කරනවා
- drift detect කරන්න පුළුවන්
- rollback පහසුයි
- PR review workflow එකක් use කරන්න පුළුවන්

## GitOps කියන්නේ මොකක්ද?

GitOps කියන්නේ infrastructure/app deployment desired state එක Git repo එකක තියාගෙන, automated controller එකක් ඒ state එක cluster එකට apply කරන workflow එක.

සරලව:

Git repo එකේ YAML වෙනස් කරනවා
→ Pull Request review/merge කරනවා
→ Argo CD ඒ change එක detect කරනවා
→ Kubernetes cluster එකට sync කරනවා

## Argo CD architecture එක

මෙම stage එකේදී Argo CD components `argocd` namespace එකේ install වෙනවා.

Main components:

- argocd-server
- argocd-repo-server
- argocd-application-controller
- argocd-redis
- argocd-dex-server

## Production meaning

Argo CD එක platform එකේ deployment control plane එක වගේ.

Developers code push කරනවා.

CI pipeline image build/test/scan කරනවා.

GitOps repo එකේ image tag හෝ manifests update වෙනවා.

Argo CD ඒ desired state එක cluster එකට deploy කරනවා.

මෙම model එකෙන් production changes audit කරලා, approve කරලා, rollback කරන්න පුළුවන්.

## Commands used in this stage

Namespace create කිරීම:

    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

Argo CD install කිරීම:

    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Pods wait කිරීම:

    kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s

Verify කිරීම:

    kubectl get pods -n argocd
    kubectl get svc -n argocd

Initial password ලබාගැනීම:

    kubectl -n argocd get secret argocd-initial-admin-secret \
      -o jsonpath="{.data.password}" | base64 -d

Local UI access:

    kubectl port-forward svc/argocd-server -n argocd 8080:443

Then open:

    https://localhost:8080

Login:

    username: admin
    password: initial admin password

## Expected result

Argo CD pods Running විය යුතුයි.

Argo CD services create වී තිබිය යුතුයි.

argocd-server service එක port-forward කරලා browser එකෙන් UI access කරන්න පුළුවන් විය යුතුයි.

## Troubleshooting

### Pods pending

Check nodes:

    kubectl get nodes

Check events:

    kubectl get events -n argocd --sort-by=.lastTimestamp

### UI certificate warning

Local port-forward HTTPS self-signed certificate warning එකක් browser එකේ පෙන්විය හැක.

Learning environment එකේ ඒක normal.

### Password not found

Initial admin secret එක Argo CD first install එකේ create වෙනවා.

Check:

    kubectl get secret -n argocd

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Argo CD install කිරීම කියන්නේ UI tool එකක් දාගැනීම විතරක් නෙවෙයි.

මෙතනින් platform එක GitOps deployment model එකට shift වෙනවා.

Git becomes the source of truth.

Cluster state should follow Git state.

## Issue faced during this stage

Argo CD install කරන වෙලාවේ `applicationsets.argoproj.io` CRD create වෙන්න fail වුණා.

Error:

    metadata.annotations: Too long: may not be more than 262144 bytes

මේ නිසා `argocd-applicationset-controller` pod එක CrashLoopBackOff වුණා.

Logs වලින් root cause එක confirm වුණා:

    no matches for kind "ApplicationSet" in version "argoproj.io/v1alpha1"

Meaning:

ApplicationSet controller එක start වුණා, නමුත් cluster එකේ ApplicationSet CRD එක තවම තිබුණේ නැහැ.

## Fix used

CRDs server-side apply කළා:

    kubectl apply --server-side=true --force-conflicts=true \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml

    kubectl apply --server-side=true --force-conflicts=true \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/appproject-crd.yaml

    kubectl apply --server-side=true --force-conflicts=true \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml

ඊට පස්සේ ApplicationSet controller restart කළා:

    kubectl rollout restart deployment/argocd-applicationset-controller -n argocd

Verify කළා:

    kubectl get crd applications.argoproj.io appprojects.argoproj.io applicationsets.argoproj.io
    kubectl api-resources | grep argoproj
    kubectl get pods -n argocd

## Production lesson

Kubernetes tool install එකකදී pods Running ද කියලා විතරක් බලන එක ප්‍රමාණවත් නැහැ.

CRDs create වෙලා තියෙනවද, controllers healthyද, logs වල errors නැද්ද, API resources availableද කියලා verify කරන්න ඕන.

GitOps platform එක incomplete නම් පස්සේ application deployment fail වෙන්න පුළුවන්.
