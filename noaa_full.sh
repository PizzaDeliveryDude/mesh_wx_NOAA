#!/bin/bash

# NOAA observations - latest
echo $(clear)

# setup
echo " - - script setup"
Begin=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin

# file location variables
ProjectDir="mesh_wx_NOAA/"
JSONFile="noaa_observations_latest.json"
FunctionsFile="functions.sh"
echo "Project Directory: "$ProjectDir
echo "JSON location: "$ProjectDir$JSONFile
echo "Functions location: "$ProjectDir$FunctionsFile

# variables
# the first variable the user can specify is the airport code, KNYC is default
UserStationId="${1:-KNYC}"
echo "UserStationId: "$UserStationId

# the second variable the user can specify is the node sending location, airport code is default
NodeLocation="${2:-$UserStationId}"
echo "Node Location: "$NodeLocation

# meshtastic radio channel, plesae do not spam your default local channel :)
Channel=2
echo "Meshtastic Channel: "$Channel

# temp JSON location for noaa_observations_latest
echo "JSON location: "$ProjectDir$JSONFile

# script functions location
# API calls and conversions are done in that file
source $ProjectDir$FunctionsFile
echo "additional script functions location: "$ProjectDir$FunctionsFile

echo ""
echo " - - fetch NOAA latest"

# fetch_noaa_latest
fetch_noaa_latest $UserStationId $ProjectDir$JSONFile
echo "fetch_noaa_latest API call"

# latest observations data
echo ""
echo " - - data"
Latitude=$(jq -r .geometry.coordinates[1] $ProjectDir$JSONFile)
echo $"Latitude: "$Latitude

Longitude=$(jq -r .geometry.coordinates[0] $ProjectDir$JSONFile)
echo $"Longitude: "$Longitude

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
WindSpeedMph=$(kph_to_mph $WindSpeed)
echo $"Wind Speed (kmh): "$WindSpeed$"Wind Speed (mph): "$WindSpeedMph

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
WxReport+=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\nConditions:'$TextDescription
WxReport+=$'\nTemp:'$FloatTemperature"°F"
WxReport+=$'\nDewpoint:'$FloatDewpoint"°F"
if [ "$WindSpeedMph" != "calm" ]; then
	WxReport+=$'\nWind:'$WindDirectionName" "$WindSpeedMph
	else
	WxReport+=$'\nWind:'$WindSpeedMph
fi
WxReport+=$'\n📍'$NodeLocation

echo $WxReport

# check how long the message is
WxReportLength=${#WxReport}
echo "WxReportLength: "$WxReportLength

echo ""
echo " - - send mesh_wx"
python -m venv ~/src/venv && source ~/src/venv/bin/activate;
echo "python stuff"

meshtastic --ch-index $Channel --sendtext "$WxReport"
#meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - noaa_location_forecast"

# location of JSON for step 1
JSONFile="noaa_location_metadata.json"

# clear contents of variable to reuse for next message
WxReport=""

# Two step process for getting forecast - https://weather-gov.github.io/api/general-faqs
# Step 1 - https://api.weather.gov/points/{lat},{lon}
#curl  https://api.weather.gov/points/40.7565,-73.9702 >> mesh_wx_NOAA/noaa_location_metadata.json
# Step 2 - Find the properties object, and inside that, find the forecast property. You’ll find another URL there.
#curl  https://api.weather.gov/gridpoints/OKX/34,37/forecast >> mesh_wx_NOAA/noaa_location_forecast.json

curl https://api.weather.gov/points/$Latitude,$Longitude > $ProjectDir$JSONFile

ForecastUrl=$(jq -r .properties.forecast $ProjectDir$JSONFile)
echo $"Forecast URL: "$ForecastUrl

JSONFile="noaa_location_forecast.json"

fetch_noaa_forecast  $ForecastUrl

# latest forecast data
echo ""
echo " - - data"
ForecastName=$(jq -r .periods[0].name $ProjectDir$JSONFile)
echo "Forecast Name: "$ForecastName

DetailedForecast=$(jq -r .periods[0].detailedForecast $ProjectDir$JSONFile)
echo "Detailed Forecast: "$DetailedForecast

echo ""
echo " - - message body"
WxReport=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\n'$ForecastName", "$DetailedForecast

echo $WxReport

# check how long the message is
WxReportLength=${#WxReport}
echo "WxReportLength: "$WxReportLength

declare -i MaxMessageLength=200
MaxMessageLength=MaxMessageLength-${#NodeLocation}
echo "Max Message Length: "$MaxMessageLength

if (($WxReportLength > MaxMessageLength)); then
	echo "message is too long, truncating"
	WxReportShort=${WxReport:0:MaxMessageLength}
	WxReportShort+=$'...end'
	WxReportLength=${#WxReportShort}
	echo "WxReportLength: "$WxReportLength
else
	WxReportShort=$WxReport
fi

WxReportShort+=$'\n📍'$NodeLocation
echo $WxReportShort

echo ""
echo " - - send mesh_wx"
python -m venv ~/src/venv && source ~/src/venv/bin/activate;
echo "python stuff"

meshtastic --ch-index $Channel --sendtext "$WxReportShort"
#meshtastic --ch-index $Channel --sendtext "$WxReportShort">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - execution times"
End=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin
echo $"Script   End: "$End

#curl "https://aa.usno.navy.mil/api/rstt/oneday?date=2025-12-01&coords=40.77,-73.98&tz=-5&dst=true" > mesh_wx_NOAA/navy_sun_moon.json 
