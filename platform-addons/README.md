# Platform Add-ons

This folder contains optional platform add-on configuration files.

These add-ons run on top of AKS.

They are not part of the core Terraform infrastructure layer.

## Current add-ons

- monitoring
- gitops

## Design principle

Terraform creates the Azure infrastructure and AKS platform.

Platform add-ons are installed separately using Helm, Kubernetes manifests, or GitOps.

This keeps the core platform flexible.

Users can choose which add-ons they want to install.

## Current structure

    platform-addons/
      monitoring/
      gitops/

## Important note

Some add-ons were installed manually during the learning build.

The values and notes in this folder help make those add-ons repeatable and easier to document.
