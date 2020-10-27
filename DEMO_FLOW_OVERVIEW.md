# DEMO FLOW OVERVIEW

## How this demo works
This information is intended for network engineers seeking to understand this demo.  

### Nested deployment templates
This demo deploys an Azure RedHat OpenShift cluster with F5 integrated in the following steps:

1. Deploys a parent template that simply deploys 6 child templates, most with dependencies so that they are ordered correctly. These are listed in the order they are deployed below.

2. Deploys a template called [vnet.json](templates/vnet.json). This template is not dependent on any other template to complete. The VNET has 5 subnets, 2 of which will be used for the OpenShift cluster, and 3 for the F5 VM's. The 2 that are used for OpenShift must have a service endpoint for the Microsoft Container Registry, and must have privateLinkServiceNetworkPolicies set to disabled. You will notice this in the template called vnet.json for those 2 subnets:
````
            "properties": {
              "addressPrefix": "[parameters('subnet4Prefix')]",
              "privateLinkServiceNetworkPolicies": "Disabled",
              "serviceEndpoints": [
                {
                  "service": "Microsoft.ContainerRegistry"
                }
              ]
            }
````

3. Deploys a template that creates a User Assigned Managed Identity (UAMI) with [uami.json](templates/uami.json). This template is also not dependent on any other template to complete. The reason this identity is created in it's own template is that I have found creating a roleAssignment and UAMI in the same template to sometimes fail, where the UAMI is not found in the directory, even when the roleAssignment is dependent on it. I suspect a very slight delay in time betweent the creation of the UAMI and when it can be discovered by a roleAssignment, but I've found creating a UAMI in a separate template and then deploying other templates to overcome this.

4. Deploys a pair of F5 VM's into the VNET using template [f5.json](templates/f5.json). This template is altered as little as possible from it's [original form](https://github.com/F5Networks/f5-azure-arm-templates/tree/master/supported/failover/same-net/via-lb/3nic/existing-stack/payg), which is a supported template from F5 Networks (this template is not officially supported).

5. Deploys a template called [updateNetwork.json](templates/updateNetwork.json). This template just applies the Network Security Group (NSG) and creates a Load Balancing rule in the Load Balancer created by the template called f5.json. This template exists so that I could edit the template called f5.json as little as possible from it's original form.

6. Deploys a template called [aro.json](templates/aro.json). This is dependent only on vnet.json. This is the template that takes around 35 minutes to deploy. It deploys an OCP cluster via ARM template, which in turn creates a ReadOnly Resource Group that contains the cluster VM's, Load Balancers, and Azure private DNS zone, and other resources that support the OpenShift cluster.

7. Deploys a script in a template called [deploymentScript.json](templates/deploymentScript.json). **This is a handy resource type to learn if you are not familiar**. This deployment script does the following
- accesses the F5 and sets up the VXLAN configuration required
- accesses the OCP cluster and completes the VXLAN configuration required
- deploys CIS into OCP
- deploys a demo app into OCP
- outputs the credentials for OCP access

8. Finally, the parent template completes when this deployment script completes. The parent template has outputs that the user can follow to complete the DNS changes that are required for verification.
### Deployment Scripts
The Azure resource of type "deployment script" is currently in public preview (as of Sept 2020) and is a very handy way to run imperative commands within a template and deployment that is intended to be declarative. Because ARM templates are intended to abstract away any scripting, you must be careful to follow best practices when using a deployment script. 
- Handle non-terminating errors in your script
- Make your script idempotent
- **Ensure all secrets passed into your script are secured**
- Use script outputs to pass values to other resources in ARM deployments
- Run your script locally using Docker and one of the supported container images.

Learn more about deployment scripts [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template).

## Handling of secrets
There are 2 secrets that must be handled in this demo.

Firstly the F5 password is input into the parent template. This is passed to the child template called f5.json as a SecureString, so you cannot see the value of this string in logs or template outputs. It is also passed to the deploymentScript resource so that the script can configure the BIG-IP. Because we do not want to pass the password as an argument (in clear text) we pass it to the container as a secure environment variable. This means that the container can access the BIG-IP when running the script, but the password is not logged anywhere and is not available to any other resource. See [this section](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#pass-secured-strings-to-deployment-script) of the documentation on Deployment Script for more info.

Secondly the password for the OCP cluster is a unique string generated by the OCP cluster deployment. It is not supplied by the user as a parameter value. However, we need this password in order to script the setup of networking in OCP, and the deployment of CIS and a demo app. We can get the password in the script because we are running as the UAMI which has Contributor permissions on the Resource Group, and we can run this command in the script:
````
ARO_CREDENTIALS=$(az aro list-credentials --name $ARO_CLUSTER_NAME --resource-group $ARO_CLUSTER_RESOURCE_GROUP)
````

You may notice that the password is an output of the deploymentScript and the parent template. This is to allow demo users to easily access the environment, but **in production you should never allow your secrets to be output in clear text** (or input into templates or container scripts in clear text.)
