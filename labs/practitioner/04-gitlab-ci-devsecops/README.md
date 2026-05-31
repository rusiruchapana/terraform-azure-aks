# Practitioner Lab 04 - GitLab CI/CD DevSecOps Checks

This lab adds DevSecOps checks to the GitLab CI/CD learning flow.

It does not require:

- Azure credentials
- Registry credentials
- Paid GitLab security features
- AKS access
- GitLab Ultimate

It does not replace Lab 03.

Lab 03 teaches:

    validate -> build_push -> deploy -> verify

This lab teaches:

    validate -> scan_config -> build_image -> scan_image -> summary

## What you will learn

- How to add security checks to GitLab CI/CD
- How to scan Dockerfile and Kubernetes YAML
- How to build a local Docker image in GitLab CI/CD
- How to scan a local container image
- How to read vulnerability findings
- How to switch from learning mode to strict gate mode

## Tool used

This lab uses Trivy for learning security scans.

Trivy can scan:

- Container images
- Filesystems
- Kubernetes configuration
- Infrastructure configuration

## Why this lab does not deploy

This lab focuses on security checks.

Deployment is already covered in Lab 03.

A later advanced lab can combine DevSecOps checks with deployment, approvals, registry policies, and environment gates.

## GitLab project structure

Use the same GitLab project from Lab 03.

Expected structure:

    app/
      Dockerfile
      index.html

    k8s/
      namespace.yaml
      deployment.yaml
      service.yaml

    .gitlab-ci.yml

## Copy the DevSecOps pipeline

The DevSecOps pipeline template is stored here:

    labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml

Copy it to your GitLab project root as:

    .gitlab-ci.yml

This can temporarily replace the Lab 03 deploy pipeline while testing DevSecOps checks.

## Pipeline stages

The pipeline uses these stages:

    validate
      |
      v
    scan_config
      |
      v
    build_image
      |
      v
    scan_image
      |
      v
    summary

## Learning mode

This lab runs in learning mode by default.

Learning mode means Trivy reports findings but does not fail the pipeline.

The workflow uses:

    --exit-code 0

## Strict security gate mode

After you understand the output, you can make the scan fail the pipeline when HIGH or CRITICAL vulnerabilities are found.

Change:

    --exit-code 0

to:

    --exit-code 1

Use strict mode carefully because public base images can contain vulnerabilities that require review, patching, or risk acceptance.

## Example scan result

It is normal for an image scan to report vulnerabilities in the base image.

This does not always mean the lab is broken.

It means the scanner found known vulnerabilities in the image layers, usually from the base operating system packages.

In a real DevSecOps workflow, review the findings and decide what to do next.

Possible actions:

- Use a newer base image
- Use a smaller base image
- Rebuild after upstream patches are available
- Change the base image family
- Document accepted risk
- Fail the pipeline only for selected severity levels
- Use strict security gates for production branches

## Cleanup

This workflow does not deploy to AKS.

No Kubernetes cleanup is required.

## Important note

This is a learning lab.

Production DevSecOps pipelines should also consider:

- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code
