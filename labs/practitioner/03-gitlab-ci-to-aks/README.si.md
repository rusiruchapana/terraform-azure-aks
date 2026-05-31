# Practitioner Lab 03 - GitLab CI/CD to AKS

මෙම lab එකෙන් GitLab CI/CD pipeline එකක් use කරලා container image එකක් build කරලා registry එකට push කරලා AKS cluster එකට deploy කරන flow එක ඉගෙන ගන්නවා.

මෙය GitHub Actions lab එකට similar concept එකක්, හැබැයි CI/CD tool එක GitLab.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitLab CI/CD pipeline structure එක
- GitLab pipeline stages
- Docker build in GitLab CI/CD
- Registry login සහ image push
- Azure login from GitLab CI/CD
- AKS deployment from GitLab CI/CD
- Rollout verification

## Lab repository

මෙම lab එකට GitLab project එකක් use කරන්න.

Example project:

    aks-gitlab-cicd-lab

GitLab project එක private තියාගන්න recommended. එතකොට secrets සහ Azure details public වෙන්නේ නැහැ.

## What this lab requires

මෙම lab එකට අවශ්‍ය දේවල්:

- GitLab account
- Private GitLab project
- GitLab CI/CD enabled
- AKS cluster
- Container registry such as ACR
- GitLab CI/CD variables

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ image එක registry එකට push කරනවා.

Pipeline run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

මෙම guide එකෙන් Azure login, subscription ID, tenant ID, service principal, ACR login server, සහ registry credentials හදාගන්න විදිය explain කරනවා.

## Required GitLab CI/CD variables

GitLab project එකේ variables add කරන්න:

    GitLab project -> Settings -> CI/CD -> Variables

Variables:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For this platform example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME = aks-dev-001
    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

For ACR, you can use:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

The service principal should have:

- Permission to get AKS credentials
- AcrPush permission on ACR

## GitLab variable settings

Secret values සඳහා:

    Masked: yes

Learning branch එකකට:

    Protected: no

Protected variables use කරන්නේ protected branches/tags එක්ක. Beginner/practitioner learning වලදී branch protection configure කරලා නැත්නම් `Protected: no` use කරන්න.

Secret ලෙස treat කරන්න ඕන values:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Folder structure

GitLab project එකේ expected structure එක:

    app/
      sample web app and Dockerfile

    k8s/
      Kubernetes manifests

    .gitlab-ci.yml
      GitLab pipeline

Lab source repo එකේ pipeline template එක තියෙන්නේ:

    gitlab-ci/.gitlab-ci.yml

## Copy files into your GitLab project

මෙම lab folder එකෙන් GitLab project root එකට මේවා copy කරන්න:

    app/
    k8s/
    gitlab-ci/.gitlab-ci.yml

GitLab project root එකේ file name එක මෙහෙම වෙන්න ඕන:

    .gitlab-ci.yml

Expected GitLab project structure:

    app/
      Dockerfile
      index.html

    k8s/
      namespace.yaml
      deployment.yaml
      service.yaml

    .gitlab-ci.yml

`.gitlab-ci.yml` file එක GitLab repo root එකේ තිබ්බම GitLab pipeline එක detect වෙනවා.

## Pipeline stages

GitLab pipeline එක stages කිහිපයකට split කරලා තියෙනවා:

    validate
      |
      v
    build_push
      |
      v
    deploy
      |
      v
    verify

මෙම flow එකෙන් pipeline එක read කරන්න සහ troubleshoot කරන්න ලේසි වෙනවා.

## How it works

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. Docker image build කරනවා
3. Image එක registry එකට push කරනවා
4. Azure login වෙනවා
5. AKS credentials ගන්නවා
6. Kubernetes manifests apply කරනවා
7. Rollout verify කරනවා

මෙම lab එක GitLab CI/CD basics සහ AKS deployment flow එක connect කරනවා.

## Verify from local machine

Pipeline success වුණාට පස්සේ local machine එකෙන් verify කරන්න:

    kubectl get pods -n practitioner-gitlab-ci
    kubectl get svc -n practitioner-gitlab-ci

App එක local machine එකට port-forward කරන්න:

    kubectl port-forward svc/gitlab-ci-demo -n practitioner-gitlab-ci 8085:80

Browser එකෙන් open කරන්න:

    http://localhost:8085

Expected:

    GitLab CI/CD demo app page එක load වෙන්න ඕන.

## Cleanup

Lab resources delete කරන්න:

    kubectl delete namespace practitioner-gitlab-ci

මෙයින් namespace එකේ තිබුණු Deployment, Service, Pod resources delete වෙනවා.

## Important note

මෙම lab එක intentionally simple.

මුලින් GitLab CI/CD flow එක තේරුම් ගන්න මෙම lab එක use කරන්න.

ඊට පස්සේ ඔබගේ own application, registry, security model, deployment strategy අනුව pipeline එක improve කරන්න.

Production වලදී consider කරන්න:

- Protected branches
- Protected variables
- Environment approvals
- Least privilege service principal
- OIDC/federated credentials where possible
- DevSecOps scans
- GitOps deployment promotion
