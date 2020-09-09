# azure-redhat-openshift-f5

## Deploy
  [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikeoleary%2Fazure-redhat-openshift-f5%2Fmain%2Fdeploy.json)

## Instructions
These instructions are intended to be run from a Linux workstation with [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed. For the official instructions from Microsoft on deploying ARO, you can view [this tutorial](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster).
1. Obtain a [pull secret from RedHat](https://www.openshift.com/try) and save it as pull-secret.txt
2. Register the provider in your Azure subscription. This only needs to be done once.
````
az provider register -n Microsoft.RedHatOpenShift --wait 
````
3. Set Variables:
````
CLUSTER=ocpcluster
RESOURCEGROUP=aro-demo
LOCATION=eastus2
VNET=($RESOURCEGROUP'-vnet')
PRIMARYSUBNET=PrimarySubnet
WORKERSUBNET=WorkerSubnet
````
4. Run this command from the directory where the pull secret was saved:
````
  az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet $VNET --master-subnet $PRIMARYSUBNET --worker-subnet $WORKERSUBNET --pull-secret @pull-secret.txt
````

## Pledge for Racial Equality, Diversity, and Inclusion
F5 has [pledged](https://www.f5.com/company/blog/our-pledge-for-racial-equality--diversity--and-inclusion) to fight against racism. Part of this effort includes updating our code and documentation to discontinue the use of terms that may be considered racially charged. To that end, this repo has removed, where possible, words such as "master" and "blacklist" and replaced them with "main" (eg, the default git branch), or "primary" (eg, the subnet name), or "denylist" (not used in this repo at the time of this writing). If you see any terms considered racially charged, please submit an issue to bring it to attention. This effort is expected to be on-going and faces some challenges (eg, hardcoded protocol terms) but over time the intent is to remove all terms that are considered racially charged. Thank you for any help in this regard.
