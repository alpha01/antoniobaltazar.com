#!/bin/bash
# Deploying portfolio to DC/OS 

MESOS_SERVER="master.rubyninja.org"
MESOS_SERVICE_ID="%2Fweb%2Fportfolio" # encoded mesos service name

RETRY_COUNT=12
SLEEP_INTERVAL=10

# Deploying app
DEPLOY=$(curl -X PUT "http://${MESOS_SERVER}/service/marathon/v2/pods/${MESOS_SERVICE_ID}?force=true" \
     -H "accept: application/json" -H "content-type: application/json" -d@dcos-portfolio-service.json | jq '.')

if [ "$?" != "0" ]; then
    echo "Deployment failed!"
    exit 1
else
    echo $DEPLOY
fi

# Verifying deployment
NEW_CONTAINERS=$(echo $DEPLOY | jq '.containers[] .image .id')

CHECK_ATTEMPT_COUNT=0
DEPLOYMENT_STATUS="pass"
while [ "$RETRY_COUNT" -gt "$CHECK_ATTEMPT_COUNT" ]; do
    POD_STATUS=$(curl -s -S -X GET "http://${MESOS_SERVER}/service/marathon/v2/pods/${MESOS_SERVICE_ID}::status" -H "accept: application/json" | jq '.')
    
    CONTAINER_STATUS=$(echo $POD_STATUS | jq '.spec .containers[] .image .id')

    for instance in $(echo "${POD_STATUS}" | jq -r '.instances[] | @base64'); do
        _jq() {
            echo ${instance} | base64 --decode | jq -r ${1}
        }
        printf "agentHostname: $(_jq '.agentHostname')\n"
        OUTPUT_HEAD="Container:|Status:|Condition:"
        OUTPUT_BODY=""
        for container in $(echo "$(_jq '.containers[]')" | jq -r '. | @base64'); do
            _jq() {
                echo ${container} | base64 --decode | jq -r ${1}
            }
            
            OUTPUT_BODY+="\n$(_jq '.name')|"
            if [ "$(_jq '.status')" != "TASK_RUNNING" ] && [ "$(_jq '.conditions[0].name')" != "healthy" ]; then
                DEPLOYMENT_STATUS="false"
            else
                OUTPUT_BODY+="$(_jq '.status')|$(_jq '.conditions[0].name')\n"
            fi
        done
        printf "${OUTPUT_HEAD}${OUTPUT_BODY}" | column -t -s '|'
        echo ""

    done
    if [ "$DEPLOYMENT_STATUS" = "pass" ] && [ "$NEW_CONTAINERS" = "$CONTAINER_STATUS" ]; then
        echo "Successfully deployed app!"
        echo $NEW_CONTAINERS
        exit 0
     else
        let CHECK_ATTEMPT_COUNT+=1
        sleep $SLEEP_INTERVAL
    fi
done
exit 1
