#!/bin/bash

#THIS SCRIPT WILL  GET ARO RESOURCE PROVIDER ObjectId. This is unique to each tenant. 

#The App Id is always 'f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875' but we want the Object Id unique to this tenant.
ARO_RP=$(az ad sp list --filter "(appId eq '$APP_ID')")
ARO_RP_OBJ_ID=$(echo $ARO_RP | jq .[].objectId -r)
echo $ARO_RP_OBJ_ID

##Output values from script to the default value for output using built in environment variable AZ_SCRIPTS_OUTPUT_PATH
JSON_OUTPUT='{"aro_rp_obj_id": "'"$ARO_RP_OBJ_ID"'"}'
echo $JSON_OUTPUT > $AZ_SCRIPTS_OUTPUT_PATH
