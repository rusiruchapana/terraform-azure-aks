# Flux GitOps Examples

This folder contains Flux desired-state examples and Kustomization patterns.

## Purpose

Use this folder for Flux Kustomization, HelmRelease, and source-controller examples.

For Flux installation notes, see:

    platform-addons/gitops/flux/

## Planned topics

- Install Flux as an optional add-on
- Bootstrap Flux with this Git repository
- Deploy an application from Git
- Use Kustomize overlays
- Use HelmRelease resources
- Detect drift
- Promote app versions from dev to qa to prod
- Practice image update automation

## Basic GitOps flow with Flux

    Git repository
        |
        v
    Flux source-controller
        |
        v
    Flux kustomize-controller or helm-controller
        |
        v
    AKS workloads

## Learning approach

Start simple:

1. Bootstrap Flux with this repository
2. Deploy one app from gitops/apps/dev
3. Change the image tag in Git
4. Watch Flux reconcile the change
5. Roll back using Git
6. Add qa and prod overlays later

## Important note

These examples are learning starters.

They are not strict production templates.

You can replace the sample app, manifests, Kustomize overlays, and release process with your own structure.
