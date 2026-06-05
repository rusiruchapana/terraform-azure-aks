# Stage 11 - GitHub Actions CI ACR Build Foundation

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි GitHub Actions භාවිතා කරලා store-front Docker image එක build කරලා Azure Container Registry එකට push කරනවා.

මේ stage එකේදී deploy automation එක තවම කරන්නේ නැහැ.

අපි prove කරන දේ:

    GitHub Actions runner
        -> Azure login with OIDC
        -> ACR login
        -> Docker Buildx setup
        -> build linux/amd64 image
        -> push image to ACR
        -> verify image tag in ACR

මේක CI/CD සහ DevSecOps වල foundation stage එකක්.

## මේ stage එක වැදගත් ඇයි?

Stage 10 වලදී අපි local machine එකෙන් manually image build/push කළා.

Stage 11 වලදී ඒ manual process එක GitHub Actions වලින් automate කරනවා.

Manual flow:

    Developer laptop
        -> docker buildx build
        -> docker push
        -> ACR

CI flow:

    GitHub Actions runner
        -> docker buildx build
        -> push to ACR

මේක production වල වැදගත්, මොකද build process එක developer laptop එකට depend වෙන්නේ නැහැ.

## Current repositories

App source repo:

    aks-capstone-store-app

GitOps repo:

    aks-capstone-gitops

Platform/Terraform repo:

    terraform-azure-aks

## Stage 11 scope

මේ stage එකේ scope එක:

    Build store-front image
    Push image to ACR
    Verify ACR tag

මේ stage එකේ scope එකට අයිති නැති දේවල්:

    GitOps repo image tag update
    Argo CD deployment
    Dev to QA promotion
    QA to Prod promotion
    Full DevSecOps gates

ඒවා next stages වලදී add කරනවා.

## Target image

ACR login server:

    <your-acr-login-server>

Image name:

    store-front

Example tag:

    stage11-v1

Final image pattern:

    <your-acr-login-server>/store-front:stage11-v1

## Why OIDC instead of client secret?

GitHub Actions Azure login කරන්න ක්‍රම දෙකක් තියෙනවා.

Less recommended method:

    Store Azure client secret in GitHub Secrets

Recommended method:

    Use GitHub OIDC federated credential

OIDC method එකෙන් long-lived password/client secret එකක් GitHub එකේ store කරන්න අවශ්‍ය නැහැ.

Production security point:

    Short-lived token
    No stored Azure password
    Better auditability
    Better secret management

## Azure identity setup

GitHub Actions වලට Azure access දෙන්න Azure App Registration එකක් සහ Service Principal එකක් use කරනවා.

Required values:

    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

GitHub Actions OIDC subject:

    repo:<github-owner>/<repo-name>:ref:refs/heads/main

Example meaning:

    Only this GitHub repo
    Only main branch
    Can request Azure token through OIDC

## AcrPush permission

GitHub Actions image push කරන්න ACR permission ඕන.

Required Azure role:

    AcrPush

Scope:

    Azure Container Registry resource

Meaning:

    GitHub Actions identity can push images to ACR.

It does not need full subscription owner access.

Good security practice:

    Give least privilege only.

## GitHub Secrets and Variables

GitHub Secrets used:

    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

GitHub Variables used:

    ACR_NAME
    ACR_LOGIN_SERVER

Difference:

    Secrets:
      sensitive values
      hidden in logs

    Variables:
      non-secret configuration values
      easier to view and manage

## GitHub CLI setup

GitHub CLI was installed and authenticated.

Check:

    gh auth status

Expected:

    Logged in to github.com

This allows us to set GitHub Actions secrets and variables from terminal.

## Set GitHub secrets

Commands:

    gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID"
    gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID"
    gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"

Verify:

    gh secret list

Expected:

    AZURE_CLIENT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_TENANT_ID

## Set GitHub variables

Commands:

    gh variable set ACR_NAME --body "$ACR_NAME"
    gh variable set ACR_LOGIN_SERVER --body "$ACR_LOGIN_SERVER"

Verify:

    gh variable list

Expected:

    ACR_NAME
    ACR_LOGIN_SERVER

## Inherited upstream workflows issue

The app repo was adapted from Microsoft AKS Store Demo.

That repo already had many existing workflows, such as:

    test-e2e
    package-store-front
    package-order-service
    release-container-images
    audit-bicep
    audit-terraform

One inherited workflow started running and got stuck.

Root cause:

    azd env new ""

The variable AZURE_ENV_NAME was empty.

Because GitHub Actions is non-interactive, the workflow could not accept user input.

This created a stuck or looping workflow behavior.

## Fix for inherited workflows

For this capstone project, inherited sample workflows were disabled.

Only the capstone CI workflow remains active:

    Build store-front image to ACR

Verify active workflows:

    gh workflow list

Expected:

    Build store-front image to ACR    active

Production lesson:

    When adapting a sample repo, always review existing workflows.
    Unused upstream workflows can accidentally run and cause failures or cloud cost.

## Workflow file

Workflow path in app repo:

    .github/workflows/build-store-front-acr.yml

Workflow name:

    Build store-front image to ACR

Trigger:

    workflow_dispatch

This means the workflow is manually triggered.

This is safe for learning because it does not run automatically on every push yet.

## Workflow responsibilities

The workflow does these steps:

    Checkout app source
    Azure login with OIDC
    Login to ACR
    Set up Docker Buildx
    Build and push store-front image
    Verify image tag in ACR

## Important workflow permissions

The workflow needs:

    id-token: write
    contents: read

Meaning:

    id-token: write
      allows GitHub Actions to request OIDC token for Azure login

    contents: read
      allows workflow to checkout repository source code

## Why Docker Buildx?

In Stage 10 we saw a real issue:

    no match for platform in manifest

This happened because image architecture did not match AKS node architecture.

To avoid that, the GitHub Actions workflow explicitly builds:

    linux/amd64

Important setting:

    platforms: linux/amd64

Production lesson:

    Always build images for the target Kubernetes node architecture.

## Run the workflow

From GitHub UI:

    Repository
        -> Actions
        -> Build store-front image to ACR
        -> Run workflow
        -> image_tag = stage11-v1

Or using GitHub CLI:

    gh workflow run "Build store-front image to ACR" -f image_tag=stage11-v1

Watch run:

    gh run watch

## Successful run result

Verified successful job:

    Build and push store-front
        Set up job
        Checkout app source
        Azure login with OIDC
        Login to ACR
        Set up Docker Buildx
        Build and push store-front image
        Verify image tag in ACR
        Complete job

Run completed successfully.

## ACR verification

After workflow success, verify ACR tags:

    az acr repository show-tags \
      --name <your-acr-name> \
      --repository store-front \
      -o table

Observed tags:

    stage10-v1
    stage11-v1

Meaning:

    stage10-v1 was pushed manually from local machine.
    stage11-v1 was pushed by GitHub Actions.

This proves CI build and push works.

## Node.js 20 deprecation warning

GitHub Actions showed a warning:

    Node.js 20 actions are deprecated

This is not a pipeline failure.

The workflow still succeeded.

Meaning:

    Some GitHub Actions currently run on Node.js 20.
    GitHub is moving JavaScript actions to Node.js 24.

Future improvement:

    Update actions when newer versions support Node.js 24.
    Or set FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 when safe.

For now, this warning is documented but does not block Stage 11.

## What Stage 11 proves

Stage 11 proves:

    GitHub Actions can authenticate to Azure without client secret.
    GitHub Actions can login to ACR.
    GitHub Actions can build store-front image.
    GitHub Actions can build linux/amd64 image.
    GitHub Actions can push image to ACR.
    ACR contains the new stage11-v1 tag.

## What Stage 11 does not do yet

Stage 11 does not update GitOps repo.

Stage 11 does not deploy to AKS.

Stage 11 does not promote to QA or Prod.

Stage 11 does not run full DevSecOps security gates yet.

These are future stages.

## How this fits into the full delivery flow

Current completed flow:

    GitHub Actions
        -> build image
        -> push to ACR

Next flow:

    GitHub Actions
        -> build image
        -> push to ACR
        -> update GitOps repo image tag
        -> Argo CD deploys to Dev

Later promotion flow:

    Same image tag
        -> Dev
        -> QA
        -> Prod

Important principle:

    Build once.
    Promote the same image across environments.

## Troubleshooting

### Issue 1 - gh command not found

Reason:

    GitHub CLI is not installed.

Fix on macOS:

    brew install gh

Login:

    gh auth login

Verify:

    gh auth status

### Issue 2 - Service principal already exists

Message:

    The service principal name is already in use.

Meaning:

    Service principal already exists.

Action:

    Continue and verify with az ad sp show.

### Issue 3 - Federated credential already exists

Message:

    FederatedIdentityCredential already exists.

Meaning:

    OIDC credential is already configured.

Action:

    Continue and verify with federated credential list.

### Issue 4 - Workflow stuck in azd env new

Reason:

    Inherited upstream workflow expected AZURE_ENV_NAME variable.

Fix:

    Disable inherited sample workflows that are not used in this capstone pipeline.

### Issue 5 - ACR push permission denied

Possible reason:

    GitHub Actions identity does not have AcrPush role.

Fix:

    Assign AcrPush role on ACR scope.

### Issue 6 - Image architecture issue

Possible symptom:

    no match for platform in manifest

Fix:

    Build with linux/amd64.

In GitHub Actions:

    platforms: linux/amd64

## Final verified state

Stage 11 final state:

    Active workflow:
      Build store-front image to ACR

    GitHub Actions status:
      Success

    ACR repository:
      store-front

    ACR tags:
      stage10-v1
      stage11-v1

    Authentication:
      Azure OIDC

    Registry permission:
      AcrPush

    Build platform:
      linux/amd64

## Learner summary

මේ stage එකෙන් අපි CI foundation එක සාර්ථකව build කළා.

Key lesson:

    CI/CD කියන්නේ එකවරම production deploy කරන magic එකක් නෙවෙයි.
    මුලින් source code එක reliable image එකක් බවට build වෙන්න ඕන.
    ඒ image එක trusted registry එකකට push වෙන්න ඕන.
    ඊට පස්සේ GitOps හරහා deploy/promotion flow එක build කරන්න පුළුවන්.

Stage 11 පස්සේ අපිට next stage එකට යන්න පුළුවන්:

    Stage 12 - CI updates GitOps repo image tag and Argo CD deploys Dev
