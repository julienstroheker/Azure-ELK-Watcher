while read p; do
  echo "Sending compute limits resutls - $p"
  az vm list-usage -l $p > ./resources/computelimit$p.json
  curl -s -H "content-type: application/json" -H "location: $p" -H "subscription-id: $AZURE_SUBSCRIPTION_ID" http://$LOGSTASHSERVER:$LOGSTASHPORT -d @./resources/computelimit$p.json &
done < ./resources/locations.txt

