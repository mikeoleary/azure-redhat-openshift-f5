# azure-redhat-openshift-f5

## Deploy
  [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikeoleary%2Fazure-redhat-openshift-f5%2Fmaster%2Fdeploy.json)

CLUSTER=ocpcluster
RESOURCEGROUP=moleary-aro
LOCATION=eastus2
VNET=($RESOURCEGROUP'-vnet')
MASTERSUBNET=MasterSubnet
WORKERSUBNET=WorkerSubnet

  az network vnet subnet update --name $MASTERSUBNET --resource-group $RESOURCEGROUP --vnet-name $VNET --disable-private-link-service-network-policies true

  az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet $VNET --master-subnet $MASTERSUBNET --worker-subnet $WORKERSUBNET
