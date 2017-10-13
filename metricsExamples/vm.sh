az vm list > resultvm.json
echo Sending VM results
curl -s -H "content-type: application/json" -H "subscription-id: $AZURE_SUBSCRIPTION_ID" http://logstash:5000 -d @resultvm.json