az storage account list > resultsa.json
echo Sending SA results
curl -s -H "content-type: application/json" -H "subscription-id: $AZURE_SUBSCRIPTION_ID" http://logstash:5000 -d @resultsa.json