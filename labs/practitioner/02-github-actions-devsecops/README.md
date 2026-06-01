# Practitioner Lab 02 - GitHub Actions DevSecOps Checks

This lab shows how to run DevSecOps checks in GitHub Actions before any deployment happens.

This is a standalone scan-only lab.

It does not deploy to AKS.

It does not push images to a container registry.

The lab uses:

- A GitHub repository where you can run GitHub Actions
- A GitHub Actions workflow template
- Trivy for security scanning
- A sample app used as an image scan target
- Kubernetes manifests used as config scan targets
- A local image build inside the GitHub Actions runner
- GitHub Actions job output for scan results

## Lab goal

By the end of this lab, you should have:

- A GitHub Actions workflow named `GitHub Actions DevSecOps Checks`
- A copied workflow file at `.github/workflows/devsecops-checks.yaml`
- A workflow run that validates required files
- A workflow run that scans repository files
- A workflow run that scans Dockerfile and Kubernetes YAML
- A workflow run that builds a local container image inside CI
- A workflow run that scans the local image
- No AKS resources created by this lab
- No container image pushed to a registry by this lab

This lab focuses on security checks only.

## What you will learn

You will learn:

- How to prepare a scan-only GitHub Actions workflow
- How to run DevSecOps checks without Azure deployment credentials
- How to scan repository files with Trivy
- How to scan Dockerfile and Kubernetes YAML with Trivy
- How to build a local image inside GitHub Actions
- How to scan the locally built image
- How to read Trivy vulnerability output
- How to decide whether findings should fail a pipeline
- Why supply-chain pinning matters for GitHub Actions
- How to clean up copied workflow files after the lab

## Lab architecture

The flow is:

    GitHub repository
      |
      v
    GitHub Actions workflow
      |
      v
    Validate files
      |
      v
    Scan repository files
      |
      v
    Scan Dockerfile and Kubernetes YAML
      |
      v
    Build local image in CI
      |
      v
    Scan local image
      |
      v
    Summary

The GitHub Actions workflow uses these jobs:

    validate
      |
      v
    scan_filesystem
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

## What this lab requires

You need:

- A GitHub account
- A GitHub repository where you can add workflow files and run GitHub Actions
- Git
- A terminal
- A web browser

This lab does not require:

- Azure credentials
- Registry credentials
- AKS access
- GitHub Advanced Security
- Paid security scanning accounts
- Docker Desktop on your local machine

The image build happens on the GitHub Actions runner.

## GitHub repository requirement

GitHub Actions workflows must live under this path in a GitHub repository:

    .github/workflows/

For this lab, use a repository that you own or maintain.

You can use your own copy of this learning repository.

Do not push lab workflow changes to a repository you do not own or maintain.

The workflow template stays in the lab folder:

    labs/practitioner/02-github-actions-devsecops/github-actions/devsecops-checks.yaml

During the lab, you copy that template to:

    .github/workflows/devsecops-checks.yaml

After the lab, remove the copied workflow if you do not want it to keep running on future pushes.

Do not delete the workflow template under the lab folder.

## Install required local tools

### Git

Install Git for your operating system:

    https://git-scm.com/downloads

Verify Git:

    git --version

Expected:

    git version should print successfully.

## Check local tools

Before continuing, verify:

    git --version

## Files in this lab

This lab includes:

    app/
      Sample static app used as an image scan target

    k8s/
      Kubernetes manifests used as config scan targets

    github-actions/
      GitHub Actions DevSecOps workflow template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    github-actions/devsecops-checks.yaml

These app and Kubernetes files are scan targets for this lab.

They are not deployed by this lab.

## Copy the workflow template

Run these commands from the `terraform-azure-aks` repository root.

Create the GitHub Actions workflow folder:

    mkdir -p .github/workflows

Copy the workflow template:

    cp labs/practitioner/02-github-actions-devsecops/github-actions/devsecops-checks.yaml \
      .github/workflows/devsecops-checks.yaml

Verify the copied workflow:

    test -f .github/workflows/devsecops-checks.yaml

## Review the workflow trigger

The workflow supports both manual and push-based execution:

    workflow_dispatch

and:

    push to main

The push trigger watches:

    labs/practitioner/02-github-actions-devsecops/**
    .github/workflows/devsecops-checks.yaml

This means the workflow can run when you push changes to the lab files or the workflow file on the `main` branch.

You can also run it manually from the GitHub Actions tab.

## Commit the workflow to your own GitHub repository

GitHub Actions can only run workflows that are committed to a GitHub repository.

Commit the copied workflow and lab files to your own repository:

    git add .github/workflows/devsecops-checks.yaml
    git add labs/practitioner/02-github-actions-devsecops

    git commit -m "Add GitHub Actions DevSecOps checks lab"
    git push

Only push to a repository that you own or maintain.

Do not push these lab workflow changes to someone else's repository.

## Run the workflow

Open your GitHub repository in a browser.

Go to:

    Actions
    GitHub Actions DevSecOps Checks

You can run the workflow in either of these ways:

Option 1, manual run:

    Run workflow
    Branch: main
    Run workflow

Option 2, push trigger:

    Push a commit to main that changes the workflow or lab files.

The workflow should run these jobs:

    validate
    scan_filesystem
    scan_config
    build_image
    scan_image
    summary

## Verify the GitHub Actions run

Open the workflow run and check that each job completed.

Expected jobs:

    validate
    scan_filesystem
    scan_config
    build_image
    scan_image
    summary

The `validate` job should confirm required files exist.

The `scan_filesystem` job should show Trivy filesystem scan output.

The `scan_config` job should show Trivy config scan output.

The `build_image` job should build a local image inside the runner.

The `scan_image` job should show Trivy image scan output.

The `summary` job should explain that this lab does not deploy to AKS.

## Expected result

The workflow should:

- Validate required files
- Scan repository files
- Scan Dockerfile and Kubernetes YAML
- Build a local Docker image in CI
- Scan the image
- Show scan results in the workflow logs
- Avoid pushing images to a registry
- Avoid deploying anything to AKS

## Example scan result

It is normal for the image scan to report vulnerabilities in the base image.

Example result:

    Total: 31 vulnerabilities
    HIGH: 29
    CRITICAL: 2

This does not mean the lab is broken.

It means the scanner found known vulnerabilities in the image layers, usually from the base operating system packages.

In a real DevSecOps workflow, you would review the findings and decide what to do next.

Possible actions:

- Use a newer base image
- Use a smaller base image
- Rebuild after upstream patches are available
- Change the base image family
- Document accepted risk
- Fail the pipeline only for selected severity levels
- Use strict security gates for production branches

## Learning mode and strict mode

This lab can be run in learning mode or strict mode depending on how the workflow is configured.

In learning mode, the workflow reports findings but does not fail immediately.

In strict mode, the workflow can fail when selected severity levels are found.

Use strict mode carefully.

Public base images can include vulnerabilities that require review, patching, or documented risk acceptance.

## Important supply-chain note

Security tools are also dependencies.

Pin action versions carefully and review upstream project security advisories.

For stronger production-style security, pin actions to trusted commit SHAs and rotate secrets if you suspect a compromised CI/CD dependency.

## Trivy notices

Trivy may print notices such as:

    A newer Trivy version is available
    VEX notice

These are informational.

They do not always mean the workflow failed.

Focus first on:

- vulnerability severity
- whether a fix is available
- whether the affected package is actually used
- whether this is a learning lab or production deployment

## What to do if the image scan fails

Read the vulnerability output.

Possible actions:

- Use a newer base image
- Use a smaller base image
- Patch dependencies
- Rebuild the image
- Accept risk only through a documented exception process

## Troubleshooting

### Workflow does not appear in the Actions tab

Verify the workflow file exists in the root GitHub Actions folder:

    .github/workflows/devsecops-checks.yaml

The workflow template under the lab folder is not enough by itself.

GitHub Actions only runs workflow files under:

    .github/workflows/

### Workflow is not triggered by push

The workflow runs on pushes to `main` only when these paths change:

    labs/practitioner/02-github-actions-devsecops/**
    .github/workflows/devsecops-checks.yaml

You can also run it manually using:

    Actions
    GitHub Actions DevSecOps Checks
    Run workflow

### Required file validation failed

If the `validate` job fails, check the files that the workflow expects:

    labs/practitioner/02-github-actions-devsecops/app/Dockerfile
    labs/practitioner/02-github-actions-devsecops/k8s/namespace.yaml
    labs/practitioner/02-github-actions-devsecops/k8s/deployment.yaml
    labs/practitioner/02-github-actions-devsecops/k8s/service.yaml

Make sure those folders exist in your repository.

### Trivy reports vulnerabilities

This is expected in many learning labs.

Read the severity, package name, installed version, fixed version, and vulnerability description.

Decide whether the finding should block the pipeline.

### Docker build failed

Check the `build_image` job logs.

Verify the Dockerfile exists:

    labs/practitioner/02-github-actions-devsecops/app/Dockerfile

### No AKS resources were created

This is expected.

This lab is scan-only and does not deploy to AKS.

## Cleanup

This lab does not create AKS resources.

This lab does not push images to a registry.

No Kubernetes or ACR cleanup is required.

If the workflow was copied only for this lab, remove it from the root GitHub Actions folder:

    rm -f .github/workflows/devsecops-checks.yaml

Do not delete the workflow template under:

    labs/practitioner/02-github-actions-devsecops/github-actions/

Commit and push the cleanup change to your own repository if you no longer want the workflow to remain active:

    git add .github/workflows/devsecops-checks.yaml
    git commit -m "Remove GitHub Actions DevSecOps checks workflow"
    git push

If the file was already removed, `git add` may need:

    git add -u .github/workflows/devsecops-checks.yaml

## Security cleanup

This lab does not use Azure credentials or registry credentials.

If you added any temporary secrets while experimenting, remove or rotate them.

Do not commit secrets into Git.

For production, prefer:

- Least privilege permissions
- OIDC federation for cloud access
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

This is a learning lab.

It teaches DevSecOps scanning in GitHub Actions without cloud deployment credentials.

A production DevSecOps workflow should combine scanning, approvals, least privilege identity, SBOM generation, image signing, and policy validation.
