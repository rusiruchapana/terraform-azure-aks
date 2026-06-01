# Practitioner Lab 04 - GitLab CI/CD DevSecOps Checks

This lab shows how to run DevSecOps checks in GitLab CI/CD before any deployment happens.

This is a standalone scan-only lab.

It does not deploy to AKS.

It does not push images to a container registry.

The lab uses:

- A GitLab project where you can run CI/CD pipelines
- A GitLab CI/CD pipeline template
- Trivy for security scanning
- A sample app used as an image scan target
- Kubernetes manifests used as config scan targets
- A local image build inside the GitLab runner
- GitLab job output for scan results

## Lab goal

By the end of this lab, you should have:

- A GitLab pipeline using `.gitlab-ci.yml`
- A workflow that validates required files
- A workflow that scans Dockerfile and Kubernetes YAML
- A workflow that builds a local container image inside CI
- A workflow that scans the local image
- No AKS resources created by this lab
- No container image pushed to a registry by this lab

This lab focuses on security checks only.

## What you will learn

You will learn:

- How to prepare a scan-only GitLab CI/CD pipeline
- How to run DevSecOps checks without Azure deployment credentials
- How to scan Dockerfile and Kubernetes YAML with Trivy
- How to build a local image inside GitLab CI/CD
- How to scan the locally built image
- How to read Trivy vulnerability output
- How to switch from learning mode to strict gate mode
- Why supply-chain pinning matters for CI/CD tools
- How to clean up copied GitLab project files after the lab

## Lab architecture

The flow is:

    GitLab project
      |
      v
    GitLab CI/CD pipeline
      |
      v
    Validate files
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

The GitLab pipeline uses these stages:

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

## What this lab requires

You need:

- A GitLab account
- A GitLab project where you can add `.gitlab-ci.yml` and run pipelines
- Git
- A terminal
- A web browser

This lab does not require:

- Azure credentials
- Registry credentials
- AKS access
- GitLab Ultimate
- Paid GitLab security features
- Docker Desktop on your local machine

The image build happens on the GitLab runner.

## GitLab project requirement

GitLab CI/CD pipelines are detected from this file in the GitLab project root:

    .gitlab-ci.yml

For this lab, use a GitLab project that you own or maintain.

Do not push lab pipeline changes to a project you do not own or maintain.

The pipeline template stays in the lab folder:

    labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml

During the lab, you copy that template to the root of your GitLab project as:

    .gitlab-ci.yml

After the lab, remove the copied pipeline file from your GitLab project if you do not want it to keep running on future pushes.

Do not delete the pipeline template under the lab folder.

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

    gitlab-ci/
      GitLab CI/CD DevSecOps pipeline template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    gitlab-ci/.gitlab-ci.yml

These app and Kubernetes files are scan targets for this lab.

They are not deployed by this lab.

## Copy files into your GitLab project

Run these commands from the `terraform-azure-aks` repository root.

Set a local path to your GitLab project clone:

    GITLAB_PROJECT_DIR="<path-to-your-gitlab-project>"

Example:

    GITLAB_PROJECT_DIR="$HOME/terraform-azure-aks-labs/aks-gitlab-devsecops-lab"

Create folders in your GitLab project:

    mkdir -p "$GITLAB_PROJECT_DIR/app"
    mkdir -p "$GITLAB_PROJECT_DIR/k8s"

Copy the lab files:

    cp labs/practitioner/04-gitlab-ci-devsecops/app/* "$GITLAB_PROJECT_DIR/app/"
    cp labs/practitioner/04-gitlab-ci-devsecops/k8s/* "$GITLAB_PROJECT_DIR/k8s/"
    cp labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml "$GITLAB_PROJECT_DIR/.gitlab-ci.yml"

Verify the GitLab project structure:

    find "$GITLAB_PROJECT_DIR" -maxdepth 3 -type f | sort

Expected files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    .gitlab-ci.yml

## Commit the pipeline to your own GitLab project

GitLab CI/CD can only run pipelines that are committed to a GitLab project.

Move into your GitLab project clone:

    cd "$GITLAB_PROJECT_DIR"

Commit the copied app, manifests, and pipeline file:

    git add app k8s .gitlab-ci.yml
    git commit -m "Add GitLab CI/CD DevSecOps checks lab"
    git push

Only push to a GitLab project that you own or maintain.

Do not push these lab pipeline changes to someone else's project.

## Run the pipeline

Open your GitLab project in a browser.

Go to:

    Build
    Pipelines

The pipeline can run when you push to the project.

If you want to run it manually, use:

    Run pipeline

The pipeline should run these stages:

    validate
    scan_config
    build_image
    scan_image
    summary

## Verify the GitLab pipeline run

Open the pipeline and check that each stage succeeded.

Expected stages:

    validate
    scan_config
    build_image
    scan_image
    summary

The `validate` stage should confirm required files exist.

The `scan_config` stage should show Trivy config scan output.

The `build_image` stage should build a local image inside the runner.

The `scan_image` stage should show Trivy image scan output.

The `summary` stage should explain that this lab does not deploy to AKS.

## Expected result

The pipeline should:

- Validate required files
- Scan Dockerfile and Kubernetes YAML
- Build a local Docker image in CI
- Save the image as `image.tar`
- Scan the image archive
- Show scan results in the pipeline logs
- Avoid pushing images to a registry
- Avoid deploying anything to AKS

## Image platform note

The pipeline builds the image for `linux/amd64`:

    docker build --platform linux/amd64 -t "$IMAGE_NAME:$CI_COMMIT_SHA" "$APP_PATH"

This is useful because most AKS node pools use amd64 nodes.

It also avoids image platform mismatch when a runner uses ARM hardware.

## Learning mode

This lab runs in learning mode by default.

Learning mode means Trivy reports findings but does not fail the pipeline.

The pipeline uses:

    --exit-code 0

## Strict security gate mode

After you understand the output, you can make the scan fail the pipeline when HIGH or CRITICAL vulnerabilities are found.

Change:

    --exit-code 0

To:

    --exit-code 1

Use strict mode carefully.

Public base images can include vulnerabilities that require review, patching, or documented risk acceptance.

## Example scan result

It is normal for an image scan to report vulnerabilities in the base image.

Example result:

    Total: 31 vulnerabilities
    HIGH: 29
    CRITICAL: 2

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

## Important supply-chain note

Security tools are also dependencies.

Pin container image versions carefully and review upstream project security advisories.

For stronger production-style security, pin tools to trusted versions and rotate secrets if you suspect a compromised CI/CD dependency.

## Trivy notices

Trivy may print notices such as:

    A newer Trivy version is available
    VEX notice

These are informational.

They do not always mean the pipeline failed.

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

### Pipeline does not start

Verify `.gitlab-ci.yml` exists in the root of your GitLab project:

    .gitlab-ci.yml

The pipeline template under the lab folder is not enough by itself.

GitLab detects pipelines from `.gitlab-ci.yml` in the project root.

### Required file validation failed

If the `validate` stage fails, verify these files exist in your GitLab project:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml

### Trivy reports vulnerabilities

This is expected in many learning labs.

Read the severity, package name, installed version, fixed version, and vulnerability description.

Decide whether the finding should block the pipeline.

### Docker build failed

Check the `build_image` stage logs.

Verify the Dockerfile exists:

    app/Dockerfile

### No AKS resources were created

This is expected.

This lab is scan-only and does not deploy to AKS.

## Cleanup

This lab does not create AKS resources.

This lab does not push images to a registry.

No Kubernetes or ACR cleanup is required.

If the files were copied only for this lab, remove them from your GitLab project clone:

    cd "$GITLAB_PROJECT_DIR"

    rm -rf app k8s .gitlab-ci.yml

Commit and push the cleanup change to your own GitLab project if you no longer want the pipeline to remain active:

    git add -A app k8s .gitlab-ci.yml
    git commit -m "Remove GitLab CI/CD DevSecOps checks lab files"
    git push

Do not delete the lab templates under:

    labs/practitioner/04-gitlab-ci-devsecops/

## Security cleanup

This lab does not use Azure credentials or registry credentials.

If you added any temporary secrets while experimenting, remove or rotate them.

Do not commit secrets into Git.

For production, prefer:

- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

This is a learning lab.

It teaches DevSecOps scanning in GitLab CI/CD without cloud deployment credentials.

A production DevSecOps pipeline should combine scanning, approvals, least privilege identity, SBOM generation, image signing, and policy validation.
