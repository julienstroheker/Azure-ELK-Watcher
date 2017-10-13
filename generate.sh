#!/bin/bash

# $MIN0$
# $MAX80$
# $MIN80$
# $MAX90$
# $MIN90$
# $MAX100$

# $FILTER$
# $CUSTOMLABEL$
# $VISUTITLE$
# $ESINDEX$

get_az_limits () {
    # Store all the compute resources
    az vm list-usage -l eastus --query '[*].[name.value,limit]' -o tsv > ./resources/computeresources.txt
    az account list-locations --query '[].name' -o tsv > ./resources/locations.txt
}

# You have to call this function with params, ordered in the function - TITLE - LABEL - VALUETOFILTER - MIN - WARNING - WARNINGMAX - MAX
generate_gauge_visu () {
    VALUEVISUTITLE=$1
    VALUECUSTOMLABEL=$2
    VALUEFILTER=$3
    VALUEFILTERLOCATION=$4

    VALUEMIN0=$5
    VALUEMAX80=$6
    VALUEMIN80=$VALUEMAX80
    VALUEMAX90=$7
    VALUEMIN90=$VALUEMAX90
    VALUEMAX100=$8

    cp ./importVisu/templategauge.json ./resources/$1.json

    sed -i 's/\$MIN0\$/'$VALUEMIN0'/g' ./resources/$1.json
    sed -i 's/\$MAX80\$/'$VALUEMAX80'/g' ./resources/$1.json

    sed -i 's/\$MIN80\$/'$VALUEMIN80'/g' ./resources/$1.json
    sed -i 's/\$MAX90\$/'$VALUEMAX90'/g' ./resources/$1.json

    sed -i 's/\$MIN90\$/'$VALUEMIN90'/g' ./resources/$1.json
    sed -i 's/\$MAX100\$/'$VALUEMAX100'/g' ./resources/$1.json

    sed -i 's/\$FILTERVALUE\$/'$VALUEFILTER'/g' ./resources/$1.json
    sed -i 's/\$FILTERLOCATION\$/'$VALUEFILTERLOCATION'/g' ./resources/$1.json
    sed -i 's/\$CUSTOMLABEL\$/'$VALUECUSTOMLABEL'/g' ./resources/$1.json
    sed -i 's/\$VISUTITLE\$/'$VALUEVISUTITLE'/g' ./resources/$1.json
    sed -i 's/\$ESINDEX\$/'$VALUEESINDEX'/g' ./resources/$1.json

    sed -i 's/\$AZURESUBID\$/'$AZURE_SUBSCRIPTION_ID'/g' ./resources/$1.json
}

generate_time_visu () {
    #Title of the visu
    VALUEVISUTITLE=$1
    #Label for the field to filter on
    VALUECUSTOMLABEL=$2
    #Field to filter on
    VALUEFILTER=$3

    cp ./importVisu/templatetime.json ./resources/$1.json


    sed -i 's/\$FILTERVALUE\$/'$VALUEFILTER'/g' ./resources/$1.json
    sed -i 's/\$CUSTOMLABEL\$/'$VALUECUSTOMLABEL'/g' ./resources/$1.json
    sed -i 's/\$VISUTITLE\$/'$VALUEVISUTITLE'/g' ./resources/$1.json
    sed -i 's/\$ESINDEX\$/'$VALUEESINDEX'/g' ./resources/$1.json

    sed -i 's/\$AZURESUBID\$/'$AZURE_SUBSCRIPTION_ID'/g' ./resources/$1.json
}

determine_es_server() {
    if curl -s -w '%{http_code}\n' "http://elasticsearch:9200" | grep -q "200"
    then
        ESSERVER="elasticsearch"
    elif curl -s -w '%{http_code}\n' "http://localhost:9200" | grep -q "200"
    then
        ESSERVER="localhost"
    else
        echo "Cannot determine the ES server"
        exit 1
    fi
}

generate_gauges_dashboard() {
    VALUEDASHBOARDTITLE=$1
    LOCATION=$2
    cp ./importDashboard/gauges/template.json ./importDashboard/$1.json

    COUNTER=1
    COUNTERCOL=1
    COUNTERROW=1
    panel=''
    echo -n "" > ./importDashboard/panel.txt
    while read -r pres limit remainder; do
        if [[ ${COUNTER} > 1 ]]; then
            panel=$panel','
        fi
        panel=$panel'{\"size_x\":2,\"size_y\":3,\"panelIndex\":'$COUNTER',\"type\":\"visualization\",\"id\":\"'$PREFIX$pres-$LOCATION-g'\",\"col\":'$COUNTERCOL',\"row\":'$COUNTERROW'}'
        COUNTER=$(($COUNTER+1))
        COUNTERCOL=$(($COUNTERCOL+2))
        if [[ ${COUNTERCOL} == 13 ]]; then
            COUNTERROW=$(($COUNTERROW+1))
            COUNTERCOL=1
        fi
    done < ./resources/computeresources.txt
    sed -i 's/\$DASHBOARDTITLE\$/'$VALUEDASHBOARDTITLE'/g' ./importDashboard/$1.json
    echo $panel
    sed -i 's/\$VISUPANELS\$/'$panel'/g' ./importDashboard/$1.json
}

determine_es_server
VALUEESINDEX=$(curl -s http://$ESSERVER:9200/.kibana/config/5.6.1 | jq -r '._source.defaultIndex')

get_az_limits

while read -r pres limit remainder; do
  while read ploc; do
    echo "Generating $PREFIX$pres-$ploc-g"
    generate_gauge_visu "$PREFIX$pres-$ploc-g" "$pres" "$pres" "$ploc" 0 $((($limit*80)/100)) $((($limit*90)/100)) $limit
    curl -s -XPUT http://$ESSERVER:9200/.kibana/visualization/$PREFIX$pres-$ploc-g --data @./resources/$PREFIX$pres-$ploc-g.json -H "content-type: application/json" > /dev/null
  done < ./resources/locations.txt
  echo "Generating $pres-t"
  generate_time_visu "$PREFIX$pres-t" "$pres" "$pres"
  curl -s -XPUT http://$ESSERVER:9200/.kibana/visualization/$PREFIX$pres-t --data @./resources/$PREFIX$pres-t.json -H "content-type: application/json" > /dev/null
done < ./resources/computeresources.txt
#generate_gauges_dashboard "titleDB" "eastus"
