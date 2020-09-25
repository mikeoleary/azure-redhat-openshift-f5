#!/bin/bash

## THIS SCRIPT WILL INSTALL F5 Cloud Failover Extension. IT REQUIRES ENVIRONMENT VARIABLES OF:
# BIGIP_MGMT_ADDRESS [this can be a single value, or a string of values separated by spaces]
# BIGIP_MGMT_PASSWORD
# CFE_DOWNLOAD_URL_PREFIX (eg. https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/)
# CFE_VERSION
# BASE_URL
# BRANCH


ARR_BIGIP_MGMT_ADDRESS=($BIGIP_MGMT_ADDRESS)
CREDS=admin:$BIGIP_MGMT_PASSWORD

#Build download url and download RPM file
FN=f5-cloud-failover-$CFE_VERSION-0.noarch.rpm
CFE_DOWNLOAD_URL=$CFE_DOWNLOAD_URL_PREFIX'v'$CFE_VERSION/$FN
wget $CFE_DOWNLOAD_URL -O /tmp/$FN

#Build download url and download CFE declaration
CONFIG_DOWNLOAD_URL=$BASE_URL$BRANCH/templates/cfe.json
wget $CONFIG_DOWNLOAD_URL -O /tmp/cfe.json

uploadCFE () {
    LEN=$(wc -c /tmp/$FN | cut -f 1 -d ' ')
    curl -kvu $CREDS https://$1/mgmt/shared/file-transfer/uploads/$FN -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((LEN - 1))/$LEN" -H "Content-Length: $LEN" -H 'Connection: keep-alive' --data-binary @/tmp/$FN
}
installCFE () {
    DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$FN\"}"
    curl -kvu $CREDS "https://$1/mgmt/shared/iapp/package-management-tasks" -H "Origin: https://$BIGIP_MGMT_ADDRESS" -H 'Content-Type: application/json;charset=UTF-8' --data $DATA
}
configureCFE() {
    BIGIP_MGMT_PRIVATE_IP_WITH_MASK=$(curl -s -k -H "Content-Type: application/json" -u $CREDS https://$i/mgmt/tm/sys/management-ip | jq .items[0].fullPath -r)
    read -a strarr <<< $(echo $BIGIP_MGMT_PRIVATE_IP_WITH_MASK | tr "/" " ")
    BIGIP_MGMT_PRIVATE_IP=${strarr[0]}
    curl -s -k -X PUT -H "Content-Type: application/json" -u $CREDS https://$i/mgmt/tm/sys/db/config.allow.rfc3927 -d '{"value":"enable"}'
    curl -s -k -X POST -H "Content-Type: application/json" -u $CREDS https://$i/mgmt/tm/sys/management-route -d '{"name":"metadata-route","network":"169.254.169.254/32", "gateway": "'"$BIGIP_MGMT_PRIVATE_IP"'"}'
    curl -s -k -X POST -H "Content-Type: application/json" -u $CREDS https://$i/mgmt/shared/cloud-failover/declare -d @/tmp/cfe.json
}

for i in "${ARR_BIGIP_MGMT_ADDRESS[@]}"
    do
    uploadCFE $i
    installCFE $i
    sleep 5
    configureCFE $i
done