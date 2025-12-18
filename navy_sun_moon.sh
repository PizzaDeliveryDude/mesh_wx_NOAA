#!/bin/bash

# Navy Sun & Moon
echo $(clear)

# setup
echo " - - script setup"
Begin=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin

# file location variables
ProjectDir="mesh_wx_NOAA/"
JSONFile="noaa_observations_latest.json"
FunctionsFile="functions.sh"
Date=$(date '+%Y-%m-%d')
declare -i TimeZone=-5
DST=$"false"

echo "Project Directory: "$ProjectDir
echo "JSON location: "$ProjectDir$JSONFile
echo "Functions location: "$ProjectDir$FunctionsFile
echo "Date: "$Date
echo "TimeZone: "$TimeZone
echo "DST: "$DST

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

# script functions location
# API calls and conversions are done in that file
source $ProjectDir$FunctionsFile
echo "additional script functions location: "$ProjectDir$FunctionsFile

echo ""
echo " - - navy sun and moon latest"


# put the curl here
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

JSONFile="navy_sun_moon.json"
# temp JSON location for navy sun and moon 
echo "JSON location: "$ProjectDir$JSONFile


curl "https://aa.usno.navy.mil/api/rstt/oneday?date=$Date&coords=$Latitude,$Longitude&tz=$TimeZone&dst=$DST" > $ProjectDir$JSONFile 

echo "Today's Moon Info:"

MoonCurrentPhase=$(jq -r .properties.data.curphase $ProjectDir$JSONFile)
echo "Current Phase: "$MoonCurrentPhase

MoonIllumination=$(jq -r .properties.data.fracillum $ProjectDir$JSONFile)
echo "Illumination: "$MoonIllumination

MoonClosestPhase=$(jq -r .properties.data.closestphase.phase $ProjectDir$JSONFile)
MoonClosestPhaseDay=$(jq -r .properties.data.closestphase.day $ProjectDir$JSONFile)
MoonClosestPhaseMonth=$(jq -r .properties.data.closestphase.month $ProjectDir$JSONFile)
MoonClosestPhaseYear=$(jq -r .properties.data.closestphase.year $ProjectDir$JSONFile)
echo "Closest Phase: "$MoonClosestPhase$" "$MoonClosestPhaseYear$"-"$MoonClosestPhaseMonth$"-"$MoonClosestPhaseDay

MoonRise=$(jq -r .properties.data.moondata[0].phen $ProjectDir$JSONFile)
MoonRiseTime=$(jq -r .properties.data.moondata[0].time $ProjectDir$JSONFile)
echo $MoonRise": "$MoonRiseTime

MoonUpperTransit=$(jq -r .properties.data.moondata[1].phen $ProjectDir$JSONFile)
MoonUpperTransitTime=$(jq -r .properties.data.moondata[1].time $ProjectDir$JSONFile)
echo $MoonUpperTransit": "$MoonUpperTransitTime

MoonSet=$(jq -r .properties.data.moondata[2].phen $ProjectDir$JSONFile)
MoonSetTime=$(jq -r .properties.data.moondata[2].time $ProjectDir$JSONFile)
echo $MoonSet": "$MoonSetTime

echo ""
echo "Today's Sun Info:"

SunBeginCivilTwilight=$(jq -r .properties.data.sundata[0].phen $ProjectDir$JSONFile)
SunBeginCivilTwilightTime=$(jq -r .properties.data.sundata[0].time $ProjectDir$JSONFile)
echo $SunBeginCivilTwilight": "$SunBeginCivilTwilightTime

SunRise=$(jq -r .properties.data.sundata[1].phen $ProjectDir$JSONFile)
SunRiseTime=$(jq -r .properties.data.sundata[1].time $ProjectDir$JSONFile)
echo $SunRise": "$SunRiseTime

SunUpperTransit=$(jq -r .properties.data.sundata[2].phen $ProjectDir$JSONFile)
SunUpperTransitTime=$(jq -r .properties.data.sundata[2].time $ProjectDir$JSONFile)
echo $SunUpperTransit": "$SunUpperTransitTime

SunSet=$(jq -r .properties.data.sundata[3].phen $ProjectDir$JSONFile)
SunSetTime=$(jq -r .properties.data.sundata[3].time $ProjectDir$JSONFile)
echo $SunSet": "$SunSetTime

SunEndCivilTwilight=$(jq -r .properties.data.sundata[4].phen $ProjectDir$JSONFile)
SunEndCivilTwilightTime=$(jq -r .properties.data.sundata[4].time $ProjectDir$JSONFile)
echo $SunEndCivilTwilight": "$SunEndCivilTwilightTime

echo ""
echo " - - moon message body"
WxReport=""
WxReport+=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\n'"Today's Moon Info:"
WxReport+=$'\n'"Current Phase:"$MoonCurrentPhase
WxReport+=$'\n'"Illumination:"$MoonIllumination
WxReport+=$'\n'"Closest Phase:"$MoonClosestPhase$" "$MoonClosestPhaseYear"-"$MoonClosestPhaseMonth"-"$MoonClosestPhaseDay
WxReport+=$'\n'"Rise:"$MoonRiseTime
WxReport+=$'\n'"Upper Transit:"$MoonUpperTransitTime
WxReport+=$'\n'"Set:"$MoonSetTime
WxReport+=$'\n📍'$NodeLocation

echo $WxReport

# check how long the message is
WxReportLength=${#WxReport}
echo "WxReportLength: "$WxReportLength

echo ""
echo " - - send mesh_wx"
#python -m venv ~/src/venv && source ~/src/venv/bin/activate;
#echo "python stuff"

#meshtastic --ch-index $Channel --sendtext "$WxReport"
#meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - sun message body"
WxReport=""
WxReport+=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\n'"Today's Sun Info:"
WxReport+=$'\n'"Begin Civil Twilight:"$SunBeginCivilTwilightTime
WxReport+=$'\n'"Rise:"$SunRiseTime
WxReport+=$'\n'"Upper Transit:"$SunUpperTransitTime
WxReport+=$'\n'"Set:"$SunSetTime
WxReport+=$'\n'"End Civil Twilight:"$SunEndCivilTwilightTime
WxReport+=$'\n📍'$NodeLocation

echo $WxReport

# check how long the message is
WxReportLength=${#WxReport}
echo "WxReportLength: "$WxReportLength

echo ""
echo " - - send mesh_wx"


#meshtastic --ch-index $Channel --sendtext "$WxReport"
#meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - execution times"
End=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin
echo $"Script   End: "$End
