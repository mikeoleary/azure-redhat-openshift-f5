# azure-redhat-openshift-f5

## Deploy
  [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikeoleary%2Fazure-redhat-openshift-f5%2Fmaster%2Fdeploy.json)

## Instructions

Set Variables:
````
CLUSTER=ocpcluster
RESOURCEGROUP=moleary-aro
LOCATION=eastus2
VNET=($RESOURCEGROUP'-vnet')
PRIMARYSUBNET=PrimarySubnet
WORKERSUBNET=WorkerSubnet
````
Now run this command:
````
  az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet $VNET --master-subnet $PRIMARYSUBNET --worker-subnet $WORKERSUBNET
````