az vmss list > resultvmss.json
echo Sending VMSS results
curl -s -H "content-type: application/json" -H "subscription-id: $AZURE_SUBSCRIPTION_ID" http://logstash:5000 -d @resultvmss.json