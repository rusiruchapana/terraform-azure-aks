# Beginner Lab 05 - Basic Kubernetes Troubleshooting

This lab helps you practice common beginner Kubernetes troubleshooting scenarios.

This is a standalone beginner lab.

The lab intentionally creates broken Kubernetes resources.

Your job is to inspect the problem, understand the error, and fix it.

## Lab goal

By the end of this lab, you should be able to troubleshoot these common Kubernetes issues:

- `ImagePullBackOff`
- Service selector mismatch
- Wrong Service `targetPort`

You should also be able to use these commands with more confidence:

- `kubectl get`
- `kubectl describe`
- `kubectl logs`
- `kubectl get endpoints`
- `kubectl get pods --show-labels`
- `kubectl port-forward`

## Learning approach

Do not open the solution first.

Recommended flow:

1. Apply the broken manifest
2. Observe the error or wrong behavior
3. Use `kubectl get`, `kubectl describe`, `kubectl logs`, and `kubectl get endpoints`
4. Try to identify the problem
5. Read the hint only if you are stuck
6. Fix the manifest yourself
7. Compare your fix with the solution
8. Apply the solution only after you understand the issue

The goal is not to copy fixed YAML.

The goal is to learn the troubleshooting thinking pattern.

## Lab architecture

This lab uses one namespace:

    beginner-troubleshooting

The scenarios are:

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

You need:

- kubectl
- Access to an AKS cluster
- A terminal
- A web browser for the port-forward test

This lab does not require:

- Docker Desktop
- Azure Container Registry
- Gateway API
- Persistent storage
- A custom container image

## Install required local tools

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

## Check local tools and AKS access

Before continuing, verify that kubectl can reach your AKS cluster:

    kubectl get nodes

Expected:

    Nodes should show Ready status.

## Files in this lab

This lab includes:

    broken/
      Intentionally broken manifests

    hints/
      Troubleshooting hints without full answers

    solutions/
      Fixed manifests for comparison

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

The broken and solution Deployments include this node selector:

    nodeSelector:
      workload: user

This means the pods will schedule only on nodes that have this label:

    workload=user

Check whether your nodes have that label:

    kubectl get nodes --show-labels | grep "workload=user" || true

If your cluster does not use this label, either add the label to a worker node or remove the `nodeSelector` from the manifests.

To label a node for this lab:

    kubectl get nodes

Then choose a node name and run:

    kubectl label node <node-name> workload=user --overwrite

## Create namespace

Run this command from the repository root:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/namespace.yaml

Verify:

    kubectl get namespace beginner-troubleshooting

## Scenario 1 - ImagePullBackOff

Apply the broken manifest:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/01-imagepullbackoff.yaml

Check pods:

    kubectl get pods -n beginner-troubleshooting

Inspect the pod:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Try to answer:

- What is the pod status?
- What image is Kubernetes trying to pull?
- Does the image tag exist?
- Is this an authentication problem or an image name/tag problem?

If you are stuck, read:

    labs/beginner/05-basic-troubleshooting/hints/01-imagepullbackoff.md

After trying your own fix, compare with:

    labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

Verify:

    kubectl rollout status deployment/imagepull-demo -n beginner-troubleshooting --timeout=180s
    kubectl get pods -n beginner-troubleshooting

Expected:

    imagepull-demo pod should become Running.

## Scenario 2 - Service selector mismatch

Apply the broken manifest:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/02-service-selector-mismatch.yaml

Check pods and service:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Check endpoints:

    kubectl get endpoints selector-demo -n beginner-troubleshooting

Inspect labels:

    kubectl get pods -n beginner-troubleshooting --show-labels

Inspect the Service:

    kubectl describe svc selector-demo -n beginner-troubleshooting

Try to answer:

- Is the pod Running?
- Does the Service have endpoints?
- What labels does the pod have?
- What selector does the Service use?
- Does the Service selector match the pod labels?

If you are stuck, read:

    labs/beginner/05-basic-troubleshooting/hints/02-service-selector-mismatch.md

After trying your own fix, compare with:

    labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

Verify endpoints:

    kubectl get endpoints selector-demo -n beginner-troubleshooting

Expected:

    selector-demo should have at least one endpoint.

## Scenario 3 - Wrong container port

Apply the broken manifest:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/broken/03-wrong-container-port.yaml

Check pods and service:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Check service details:

    kubectl describe svc wrong-port-demo -n beginner-troubleshooting

Check endpoints:

    kubectl get endpoints wrong-port-demo -n beginner-troubleshooting

Try port-forward:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open:

    http://localhost:8083

Try to answer:

- Is the pod Running?
- Does the Service have endpoints?
- Does the Service point to the correct `targetPort`?
- Which port does NGINX actually listen on?

If you are stuck, read:

    labs/beginner/05-basic-troubleshooting/hints/03-wrong-container-port.md

After trying your own fix, compare with:

    labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

Try port-forward again:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open:

    http://localhost:8083

Expected:

    The default NGINX welcome page should appear.

Stop the port-forward with:

    Ctrl+C

## Useful troubleshooting commands

List pods:

    kubectl get pods -n beginner-troubleshooting

List pods with labels:

    kubectl get pods -n beginner-troubleshooting --show-labels

Describe a pod:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

View pod logs:

    kubectl logs -n beginner-troubleshooting <pod-name>

List services:

    kubectl get svc -n beginner-troubleshooting

Describe a service:

    kubectl describe svc <service-name> -n beginner-troubleshooting

View service endpoints:

    kubectl get endpoints -n beginner-troubleshooting

Check deployments:

    kubectl get deployment -n beginner-troubleshooting

Check events:

    kubectl get events -n beginner-troubleshooting --sort-by=.lastTimestamp

## Troubleshooting tips

### ImagePullBackOff pattern

Use:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Look at:

    Events

Common cause:

    Wrong image name or image tag

### Service selector mismatch pattern

Use:

    kubectl get endpoints -n beginner-troubleshooting
    kubectl get pods -n beginner-troubleshooting --show-labels
    kubectl describe svc <service-name> -n beginner-troubleshooting

Common cause:

    Service selector does not match pod labels

### Wrong targetPort pattern

Use:

    kubectl describe svc <service-name> -n beginner-troubleshooting

Compare:

    Service targetPort
    Container port
    Application listen port

Common cause:

    Service sends traffic to a port where the container is not listening

## Cleanup

Delete the lab namespace:

    kubectl delete namespace beginner-troubleshooting --ignore-not-found

This removes all resources created by this lab.

If you added the `workload=user` label only for this lab and want to remove it, run:

    kubectl label node <node-name> workload-

## Important note

This lab intentionally creates broken resources.

Seeing errors is expected.

Troubleshooting is not about memorizing commands.

A good troubleshooting flow is:

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

The scenarios are simple, but the same thinking pattern applies to real Kubernetes issues.
