# Beginner Lab 05 - Basic Kubernetes Troubleshooting

This lab helps you practice common beginner Kubernetes troubleshooting scenarios.

Unlike earlier labs, this lab intentionally creates broken resources.

Your job is to inspect the problem, understand the error, and fix it.

## Learning approach

Do not open the solution first.

Recommended flow:

1. Apply the broken manifest
2. Observe the error
3. Use kubectl get, describe, logs, and endpoints
4. Try to identify the problem
5. Read the hint only if you are stuck
6. Fix the manifest yourself
7. Compare your fix with the solution

## Folder structure

    broken/
      intentionally broken manifests

    hints/
      troubleshooting hints without full answers

    solutions/
      answer key manifests for comparison

## What you will learn

- Use kubectl get
- Use kubectl describe
- Use kubectl logs
- Use kubectl get endpoints
- Identify ImagePullBackOff
- Identify Service selector mismatch
- Identify wrong container port issues
- Fix broken Kubernetes manifests
- Clean up lab resources safely

## Create namespace

From the repository root:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/namespace.yaml

## Scenario 1 - ImagePullBackOff

Apply the broken manifest:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/01-imagepullbackoff.yaml

Check pods:

    kubectl get pods -n beginner-troubleshooting

Inspect the pod:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Try to answer:

- What is the pod status?
- What image is Kubernetes trying to pull?
- Does the image tag exist?
- Is this an authentication problem or an image name/tag problem?

If stuck, read:

    hints/01-imagepullbackoff.md

After trying your own fix, compare with:

    solutions/01-imagepullbackoff-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/01-imagepullbackoff-fixed.yaml

## Scenario 2 - Service selector mismatch

Apply the broken manifest:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/02-service-selector-mismatch.yaml

Check pods and service:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Check endpoints:

    kubectl get endpoints -n beginner-troubleshooting

Inspect labels:

    kubectl get pods -n beginner-troubleshooting --show-labels

Try to answer:

- Is the pod Running?
- Does the Service have endpoints?
- Does the Service selector match the pod labels?

If stuck, read:

    hints/02-service-selector-mismatch.md

After trying your own fix, compare with:

    solutions/02-service-selector-mismatch-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/02-service-selector-mismatch-fixed.yaml

## Scenario 3 - Wrong container port

Apply the broken manifest:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/broken/03-wrong-container-port.yaml

Check pods and service:

    kubectl get pods -n beginner-troubleshooting
    kubectl get svc -n beginner-troubleshooting

Check service details:

    kubectl describe svc wrong-port-demo -n beginner-troubleshooting

Try port-forward:

    kubectl port-forward svc/wrong-port-demo -n beginner-troubleshooting 8083:80

Open:

    http://localhost:8083

Try to answer:

- Is the pod Running?
- Does the Service point to the correct targetPort?
- Which port does NGINX actually listen on?

If stuck, read:

    hints/03-wrong-container-port.md

After trying your own fix, compare with:

    solutions/03-wrong-container-port-fixed.yaml

Apply the solution only after attempting the fix:

    kubectl apply -f terraform-azure-aks/labs/beginner/05-basic-troubleshooting/solutions/03-wrong-container-port-fixed.yaml

## Useful troubleshooting commands

List pods:

    kubectl get pods -n beginner-troubleshooting

Describe a pod:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

View logs:

    kubectl logs -n beginner-troubleshooting <pod-name>

List services:

    kubectl get svc -n beginner-troubleshooting

View service endpoints:

    kubectl get endpoints -n beginner-troubleshooting

Show pod labels:

    kubectl get pods -n beginner-troubleshooting --show-labels

## Cleanup

Delete the namespace:

    kubectl delete namespace beginner-troubleshooting

This removes all resources created by this lab.

## Important note

This lab intentionally creates broken resources.

Seeing errors is expected.

The goal is to learn how to investigate and fix them.
