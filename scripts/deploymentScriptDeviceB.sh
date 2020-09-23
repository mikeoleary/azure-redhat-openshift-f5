#!/bin/bash

## THIS SCRIPT WILL CONFIGURE THE OCP CLUSTER AND BIG-IP TO PREPARE FOR CIS INTEGRATION VIA VXLAN OVERLAY
ARO_CLUSTER_NAME=$1
ARO_CLUSTER_RESOURCE_GROUP=$2
BIGIP_MGMT_ADDRESS=$3
BIGIP_VSERVER_ADDR=$4
BIGIP_MGMT_PASSWORD=$5

#Get ARO cluster details, and password
ARO_CREDENTIALS=$(az aro list-credentials --name $ARO_CLUSTER_NAME --resource-group $ARO_CLUSTER_RESOURCE_GROUP)
ARO_USERNAME=$(echo $ARO_CREDENTIALS | jq .kubeadminUsername -r)
ARO_PASSWORD=$(echo $ARO_CREDENTIALS | jq .kubeadminPassword -r)
ARO_CONFIG=$(az aro show --name $ARO_CLUSTER_NAME --resource-group $ARO_CLUSTER_RESOURCE_GROUP)
#Extract the subnets and API and Console addresses of ARO cluster
ARO_API_SERVER=$(echo $ARO_CONFIG | jq .apiserverProfile.url -r) 

##Download OC client tool
wget https://raw.githubusercontent.com/mikeoleary/azure-redhat-openshift-f5/main/client/openshift-client-linux.tar.gz -O /tmp/openshift-client-linux.tar.gz
tar -xf /tmp/openshift-client-linux.tar.gz -C /tmp
mv /tmp/oc /usr/local/bin -f
mv /tmp/kubectl /usr/local/bin -f

#get BIGIP IP addresses needed by CIS
#Get private IP for Internal SelfIP
BIGIP_INT_SELFIP_WITH_MASK=$(curl -s -k -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/net/self/self_3nic | jq .address -r)
read -a strarr <<< $(echo $BIGIP_INT_SELFIP_WITH_MASK | tr "/" " ")
BIGIP_INT_SELFIP=${strarr[0]}
#Get Internal vlan gw
BIGIP_INT_GW="${BIGIP_INT_SELFIP%.*}.1"
#Get private IP for Mgmt 
BIGIP_MGMT_PRIVATE_IP_WITH_MASK=$(curl -s -k -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/sys/management-ip | jq .items[0].fullPath -r)
read -a strarr <<< $(echo $BIGIP_MGMT_PRIVATE_IP_WITH_MASK | tr "/" " ")
BIGIP_MGMT_PRIVATE_IP=${strarr[0]}

##Download and edit yaml file template for hostsubnet, then apply new hostsubnet
wget https://raw.githubusercontent.com/mikeoleary/azure-redhat-openshift-f5/main/templates/f5-bigip-node.yaml  -O /tmp/f5-bigip-node.yaml
sed -i -e "s/<INTERNALSELFIP>/$BIGIP_INT_SELFIP/" /tmp/f5-bigip-node.yaml
sed -i -e "s/<NODENAME>/f5-bigip-node02/" /tmp/f5-bigip-node.yaml
oc login $ARO_API_SERVER -u=kubeadmin -p=$ARO_PASSWORD
oc apply -f /tmp/f5-bigip-node.yaml

#get cluster network mask. This is usually /14
CLUSTERNETWORK=$(oc get clusternetwork -o json | jq .items[0].network -r)
read -a strarr <<< $(echo $CLUSTERNETWORK | tr "/" " ")
CLUSTERNETWORK_MASK=${strarr[1]}

#Calculate a self IP for tunnel on BIGIP. First get assigned host subnet, which is usually a /23 range like 10.130.2.0/23. We will assign .100 from this range, eg, 10.130.2.100
BIGIP_HOST_SUBNET_WITH_MASK=$(oc get hostsubnet f5-bigip-node02 -o json | jq .subnet -r)
read -a strarr <<< $(echo $BIGIP_HOST_SUBNET_WITH_MASK | tr "/" " ")
BIGIP_HOST_SUBNET=${strarr[0]}
BIGIP_TUNNEL_SELFIP="${BIGIP_HOST_SUBNET%.*}.100/$CLUSTERNETWORK_MASK"

###Connect to BIG-IP and create tunnel profile, tunnel, selfIP on tunnel, and add vxlan port 4789 to internal self IP. Also, create a route so that the openshift worker and master nodes are reached via BIG-IP internal NIC.
#Create multipoint vxlan profile
curl -s -k -X POST -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/net/tunnels/vxlan -d '{"name": "vxlan-mp", "floodingType": "multipoint" }'
#Create vxlan tunnel based on vxlan profile
curl -s -k -X POST -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/net/tunnels/tunnel -d '{"name": "openshift_vxlan", "key": "0", "profile": "vxlan-mp", "localAddress": "'"$BIGIP_INT_SELFIP"'" }'
#Create selfIP on tunnel
curl -s -k -X POST -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/net/self -d '{"name": "tunnelSelfIP", "address": "'"$BIGIP_TUNNEL_SELFIP"'", "vlan": "openshift_vxlan", "profile": "vxlan-mp", "localAddress": "'"$BIGIP_INT_SELFIP"'", "allowService": "all" }'
#set allowed services on selfIP of Internal VLAN to be default + tcp:4789
curl -s -k -X PATCH -H "Content-Type: application/json" -u admin:$BIGIP_MGMT_PASSWORD https://$BIGIP_MGMT_ADDRESS/mgmt/tm/net/self/self_3nic -d '{"allowService": ["default","tcp:4789"]}'

##Deploy F5 CIS
rm /tmp/cis.yaml -f
wget https://raw.githubusercontent.com/mikeoleary/azure-redhat-openshift-f5/main/cis/cis.yaml -O /tmp/cis.yaml
BIGIP_MGMT_PASSWORD_BASE64=$(echo -n  $BIGIP_MGMT_PASSWORD | base64)
sed -i -e "s/<base64password>/$BIGIP_MGMT_PASSWORD_BASE64/" /tmp/cis.yaml
sed -i -e "s/<bigipUrl>/$BIGIP_MGMT_PRIVATE_IP/" /tmp/cis.yaml
sed -i -e "s/<vserver-addr>/$BIGIP_VSERVER_ADDR/" /tmp/cis.yaml
oc apply -f /tmp/cis.yaml