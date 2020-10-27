# Azure RedHat OpenShift (ARO) with F5

## Pre-requisites
1. **You will need a Service Principal (SP) in AzureAD with a secret. This SP will require Contributor permissions on the Resource Group into which you deploy.** In practice, this means either create a Resource Group prior to deploying into it, and give a SP Contributor rights, or, use a SP with Contributor rights over the subscription.

2. If not already registered, **you will need to register the following resource providers** . This only needs to be done once per subscription. You can do this via the [portal](images/register-resource-provider.PNG), or by using [Azure PowerShell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types#azure-powershell) or [Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types#azure-cli).  

PowerShell:  
  ```powershell
  #Using the new Azure PowerShell Az module
  Register-AzResourceProvider -ProviderNamespace Microsoft.RedHatOpenShift
  Register-AzResourceProvider -ProviderNamespace Microsoft.ContainerInstance
  Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
  ``` 
Azure CLI:  
  ```bash
  az provider register --namespace 'Microsoft.RedHatOpenShift'
  az provider register --namespace 'Microsoft.ContainerInstance'
  az provider register --namespace 'Microsoft.Storage'
  ```

3. You will need the **Object Id of the ARO Resource Provider** in your directory. Get this from the Azure portal ([screenshot](images/ARO-RP.PNG)) or by running:

PowerShell:  
  ```powershell
  #Using the new Azure PowerShell Az module
  Get-AzureADServicePrincipal -ApplicationId 'f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875'
  ``` 
Azure CLI:  
  ```bash
  az ad sp list --filter "(appId eq 'f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875')"
  ```

## Instructions
Instructions for deploying this demo environment with F5 via ARM template are below:
1. **Deploy ARM template** by clicking the Deploy button below.  

  [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikeoleary%2Fazure-redhat-openshift-f5%2Fmain%2Fdeploy.json)  
  
2. **Create or edit a public DNS record** so that the Custom DNS Record you entered into the deployment points to the IP address value in the output called `publicExternalLoadBalancerAddress`.
3. **Optionally, further configure** F5 and OpenShift environment by accessing the environment via the URL's in the deployment outputs.

Alternatively, for the official instructions from Microsoft on deploying ARO, you can view [this tutorial](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster). These instructions are intended to be run from a Linux workstation with [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed. However, following these instructions will not create the architecture pictured below, which is the intention of this ARM deployment above.

## Architecture
![Image of Architecture](images/ARO-with-f5.png)

## Learning this demo
Engineers or customers who would like to learn how this demo works should read [DEMO_FLOW_OVERVIEW.md](DEMO_FLOW_OVERVIEW.md). This document outlines the flow of the demo and is purely for educational purposes.

## Pledge for Racial Equality, Diversity, and Inclusion
I do not represent F5 and the code in this repo is my own, but I do work for F5. F5 has [pledged](https://www.f5.com/company/blog/our-pledge-for-racial-equality--diversity--and-inclusion) to fight against racism, and I have joined that pledge. Part of this effort includes updating our code and documentation to discontinue the use of terms that may be considered racially charged.  
  
To that end, this repo has removed, where possible, words such as "master" and "blacklist" and replaced them with "main" (eg, the default git branch), or "primary" (eg, the subnet name), or "denylist" (not used in this repo at the time of this writing). If you see any terms considered racially charged, please submit an issue to bring it to attention. This effort is expected to be on-going and faces some challenges (eg, hardcoded protocol terms) but over time the intent is to remove all terms that are considered racially charged. Thank you for any help in this regard.

## Support and Issues
This repo is hosted in a personal account, and this solution is not an officially supported solution. However, please [submit an issue](https://github.com/mikeoleary/azure-redhat-openshift-f5/issues) if you find a problem or have a question. Thanks for any co-operation and support.
