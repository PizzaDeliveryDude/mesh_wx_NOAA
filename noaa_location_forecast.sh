#!/bin/bash

# NOAA observations - latest
echo $(clear)

# setup
echo ""
echo " - - script setup"
Begin=$(date '+%Y-%m-%d %H:%M:%S')

# file location variables
ProjectDir="mesh_wx_NOAA/"
JSONFile="noaa_location_forecast.json"
FunctionsFile="functions.sh"

# variables
UserStationId="KLGB"
echo "UserStationId: "$UserStationId

NodeLocation="Hotel Room 420"
echo "Node Location: "$NodeLocation

Channel=2
echo "Meshtastic Channel: "$Channel

# temp JSON location
echo "JSON location: "$ProjectDir$JSONFile

# script FunctionsFile location
source $ProjectDir$FunctionsFile
echo "additional script functions location: "$ProjectDir$FunctionsFile

echo ""
echo " - - fetch NOAA latest"

# fetch_noaa_forecast
fetch_noaa_forecast

# latest forecast data
echo ""
echo " - - data"
ForecastName=$(jq -r .periods[0].name $ProjectDir$JSONFile)
echo "Forecast Name: "$ForecastName

DetailedForecast=$(jq -r .periods[0].detailedForecast $ProjectDir$JSONFile)
echo "Detailed Forecast: "$DetailedForecast

echo ""
echo " - - message body"
WxReport=""
WxReport+=$ForecastName", "$DetailedForecast
WxReport+=$'\n📍'$NodeLocation

echo $WxReport

echo ""
echo " - - send mesh_wx"
python -m venv ~/src/venv && source ~/src/venv/bin/activate;
echo "python stuff"

meshtastic --ch-index $Channel --sendtext "$WxReport"
#meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - execution times"
End=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin
echo $"Script   End: "$End

# Two step process for getting forecast - https://weather-gov.github.io/api/general-faqs
# Step 1 - https://api.weather.gov/points/{lat},{lon}
#curl  https://api.weather.gov/points/40.7565,-73.9702 >> mesh_wx_NOAA/noaa_location_metadata.json
# Step 2 - Find the properties object, and inside that, find the forecast property. You’ll find another URL there.
#curl  https://api.weather.gov/gridpoints/OKX/34,37/forecast >> mesh_wx_NOAA/noaa_location_forecast.json

