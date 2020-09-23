#!/bin/bash

## THIS SCRIPT WILL INSTALL F5 Cloud Failover Extension. IT REQUIRES ENVIRONMENT VARIABLES OF:
# BIGIP_MGMT_ADDRESS
# BIGIP_MGMT_PASSWORD
# CFE_DOWNLOAD_URL_PREFIX (eg. https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/)
# CFE_VERSION

#Build download url and download RPM file
FN=f5-cloud-failover-$CFE_VERSION-0.noarch.rpm
CFE_DOWNLOAD_URL=$CFE_DOWNLOAD_URL_PREFIX'v'$CFE_VERSION/$FN
wget $CFE_DOWNLOAD_URL -O /tmp/$FN

CREDS=admin:$BIGIP_MGMT_PASSWORD
#Upload CFE
LEN=$(wc -c /tmp/$FN | cut -f 1 -d ' ')
curl -kvu $CREDS https://$BIGIP_MGMT_ADDRESS/mgmt/shared/file-transfer/uploads/$FN -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((LEN - 1))/$LEN" -H "Content-Length: $LEN" -H 'Connection: keep-alive' --data-binary @/tmp/$FN
#Install CFE
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$FN\"}"
curl -kvu $CREDS "https://$BIGIP_MGMT_ADDRESS/mgmt/shared/iapp/package-management-tasks" -H "Origin: https://$BIGIP_MGMT_ADDRESS" -H 'Content-Type: application/json;charset=UTF-8' --data $DATA