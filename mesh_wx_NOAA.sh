#!/bin/bash

# NOAA observations - latest
echo $(clear)

# setup
echo ""
echo " - - script setup"
Begin=$(date '+%Y-%m-%d %H:%M:%S')

# file location variables
ProjectDir="mesh_wx_NOAA/"
JSONFile="noaa_observations_latest.json"
FunctionsFile="functions.sh"

# variables
UserStationId="KLAX"
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

# fetch_noaa_latest
fetch_noaa_latest $UserStationId $ProjectDir$JSONFile

# latest observations data
echo ""
echo " - - data"
Coordinates=$(jq -r .geometry.coordinates $ProjectDir$JSONFile)
echo $"Coordinates: "$Coordinates

Station=$(jq -r .properties.station $ProjectDir$JSONFile)
echo $"Station: "$Station

StationId=$(jq -r .properties.stationId $ProjectDir$JSONFile)
echo $"StationId: "$StationId

StationName=$(jq -r .properties.stationName $ProjectDir$JSONFile)
echo $"StationName: "$StationName

Timestamp=$(jq -r .properties.timestamp $ProjectDir$JSONFile)
echo $"Timestamp: "$Timestamp

TextDescription=$(jq -r .properties.textDescription $ProjectDir$JSONFile)
echo $"TextDescription: "$TextDescription

Temperature=$(jq -r .properties.temperature.value $ProjectDir$JSONFile)
FloatTemperature=$(c_to_f $(echo "$Temperature" | bc))
echo $"Temperature (°C): "$Temperature$" Converted Temperature (°F): "$FloatTemperature

Dewpoint=$(jq -r .properties.dewpoint.value $ProjectDir$JSONFile)
FloatDewpoint=$(c_to_f $(echo "$Dewpoint" | bc))
echo $"Dewpoint (°C): "$Dewpoint$" Converted Dewpoint (°F): "$FloatDewpoint

WindDirection=$(jq -r .properties.windDirection.value $ProjectDir$JSONFile)
WindDirectionName=$(wind_dir_name $WindDirection)
echo $"Wind Direction (°): "$WindDirection$" Wind Direction Name: "$WindDirectionName

WindSpeed=$(jq -r .properties.windSpeed.value $ProjectDir$JSONFile)
echo $"Wind Speed (kmh): "$WindSpeed

WindGust=$(jq -r .properties.windGust.value $ProjectDir$JSONFile)
echo $"Wind Gust (kmh): "$WindGust

BarometricPressure=$(jq -r .properties.barometricPressure.value $ProjectDir$JSONFile)
echo $"Barometric Pressure (Pa): "$BarometricPressure

SeaLevelPressure=$(jq -r .properties.seaLevelPressure.value $ProjectDir$JSONFile)
echo $"Sea Level Pressure (Pa): "$SeaLevelPressure

Visibility=$(jq -r .properties.visibility.value $ProjectDir$JSONFile)
echo $"Visibility (m): "$Visibility

MaxTemperatureLast24Hours=$(jq -r .properties.maxTemperatureLast24Hours.value $ProjectDir$JSONFile)
echo $"MaxTemperatureLast24Hours (°C): "$MaxTemperatureLast24Hours

MinTemperatureLast24Hours=$(jq -r .properties.minTemperatureLast24Hours.value $ProjectDir$JSONFile)
echo $"MinTemperatureLast24Hours (°C): "$MinTemperatureLast24Hours

PrecipitationLastHour=$(jq -r .properties.precipitationLastHour.value $ProjectDir$JSONFile)
echo $"PrecipitationLastHour (mm): "$PrecipitationLastHour

PrecipitationLast3Hours=$(jq -r .properties.precipitationLast3Hours.value $ProjectDir$JSONFile)
echo $"PrecipitationLast3Hours (mm): "$PrecipitationLast3Hours

PrecipitationLast6Hours=$(jq -r .properties.precipitationLast6Hours.value $ProjectDir$JSONFile)
echo $"PrecipitationLast6Hours (mm): "$PrecipitationLast6Hours

RelativeHumidity=$(jq -r .properties.relativeHumidity.value $ProjectDir$JSONFile)
echo $"RelativeHumidity (%): "$RelativeHumidity

WindChill=$(jq -r .properties.windChill.value $ProjectDir$JSONFile)
FloatWindChill=$(c_to_f $(echo "$WindChill" | bc))
echo $"Wind Chill (°C) : "$WindChill$" Converted Wind Chill (°F): "$FloatWindChill

HeatIndex=$(jq -r .properties.heatIndex.value $ProjectDir$JSONFile)
FloatHeatIndex=$(c_to_f $(echo "$HeatIndex" | bc))
echo $"Heat Index (°C): "$HeatIndex$" Converted Heat Index (°F): "$FloatHeatIndex

echo ""
echo " - - message body"
WxReport=""
WxReport+=$StationName
WxReport+=$'\n'$(date '+%H:%M:%S')
WxReport+=$'\nConditions:'$TextDescription
WxReport+=$'\nTemp:'$FloatTemperature"°F"
WxReport+=$'\nDewpoint:'$FloatDewpoint"°F"
WxReport+=$'\nWind:'$WindDirectionName" "$WindSpeed" kmph"
WxReport+=$'\n📍'$NodeLocation

echo $WxReport

#echo $StationName
#echo $(date '+%H:%M:%S')
#echo "Conditions:"$TextDescription
#echo "Temp:"$FloatTemperature"°F"
#echo "Dewpoint:"$FloatDewpoint"°F"
#echo "Wind:"$WindDirectionName" "$WindSpeed" kmph"
#echo "📍"$NodeLocation



echo ""
echo " - - send mesh_wx"
python -m venv ~/src/venv && source ~/src/venv/bin/activate;
echo "python stuff"

meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1
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

