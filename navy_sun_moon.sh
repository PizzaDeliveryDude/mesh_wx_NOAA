#!/bin/bash
# gpt-5 mini wrote this in GitHub Copilot
# log_to_noaa - read stdin and append each input line to mesh_wx_DEV/noaa_full.log
# prefixed with a timestamp in square brackets: [YYYY-MM-DD HH:MM:SS]
#
# Usage examples:
#   printf "hello\nworld\n" | log_to_noaa
#   some_command 2>&1 | log_to_noaa    # capture stdout+stderr of some_command
#
# By default logs to relative path: mesh_wx_DEV/noaa_full.log
# You can override the log path by passing it as the first arg:
#   printf "x\n" | log_to_noaa /path/to/other.log

log_to_noaa() {
  local log_file="${1:-mesh_wx_DEV/navy_sun_moon.log}"

  # Ensure directory exists
  mkdir -p -- "$(dirname -- "$log_file")"

  # Read stdin line-by-line and append timestamped lines to the log file.
  # The '|| [ -n "$line" ]' ensures the last line is handled even if it doesn't end with a newline.
  while IFS= read -r line || [ -n "$line" ]; do
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line" >> "$log_file"
  done
}
# some_command 2>&1 | log_to_noaa
# printf "This is a test\n" | log_to_noaa
# printf "hi\n" | log_to_noaa /absolute/or/relative/path/noaa_full.log

# Navy Sun & Moon
echo $(clear)
printf "+------------------------------------+" | log_to_noaa
printf "|     BEGIN NAVY SUN MOON SH LOG     |" | log_to_noaa
printf "+------------------------------------+" | log_to_noaa
# setup
Begin=$(date '+%Y-%m-%d %H:%M:%S')
printf "Script Begin: $Begin" | log_to_noaa

# file location variables
ProjectDir="mesh_wx_NOAA/"
JSONFile="noaa_observations_latest.json"
FunctionsFile="functions.sh"
Date=$(date '+%Y-%m-%d')
declare -i TimeZone=-5
DST=$"false"

printf "Project Directory: $ProjectDir" | log_to_noaa
printf "JSON location: $ProjectDir$JSONFile" | log_to_noaa
printf "Functions location: $ProjectDir$FunctionsFile" | log_to_noaa
printf "Date: $Date" | log_to_noaa
printf "TimeZone: $TimeZone" | log_to_noaa
printf "DST: $DST" | log_to_noaa

# variables
# the first variable the user can specify is the airport code, KNYC is default
UserStationId="${1:-KNYC}"
printf "UserStationId: $UserStationId" | log_to_noaa

# the second variable the user can specify is the node sending location, airport code is default
NodeLocation="${2:-$UserStationId}"
printf "Node Location: $NodeLocation" | log_to_noaa

# meshtastic radio channel, plesae do not spam your default local channel :)
Channel="${3:-0}"
printf "Meshtastic Channel: $Channel" | log_to_noaa

# script functions location
# API calls and conversions are done in that file
source $ProjectDir$FunctionsFile
printf "additional script functions location: $ProjectDir$FunctionsFile" | log_to_noaa

# put the curl here
fetch_noaa_latest $UserStationId $ProjectDir$JSONFile
printf "fetch_noaa_latest $UserStationId $ProjectDir$JSONFile" | log_to_noaa

# latest observations data
Latitude=$(jq -r .geometry.coordinates[1] $ProjectDir$JSONFile)
printf "Latitude: $Latitude" | log_to_noaa

Longitude=$(jq -r .geometry.coordinates[0] $ProjectDir$JSONFile)
printf "Longitude: $Longitude" | log_to_noaa

Station=$(jq -r .properties.station $ProjectDir$JSONFile)
printf "Station: $Station" | log_to_noaa

StationId=$(jq -r .properties.stationId $ProjectDir$JSONFile)
printf "StationId: $StationId" | log_to_noaa

StationName=$(jq -r .properties.stationName $ProjectDir$JSONFile)
printf "StationName: $StationName" | log_to_noaa

JSONFile="navy_sun_moon.json"
# temp JSON location for navy sun and moon 
printf "JSON location: $ProjectDir$JSONFile" | log_to_noaa


curl "https://aa.usno.navy.mil/api/rstt/oneday?date=$Date&coords=$Latitude,$Longitude&tz=$TimeZone&dst=$DST" > $ProjectDir$JSONFile 
printf "https://aa.usno.navy.mil/api/rstt/oneday?date=$Date&coords=$Latitude,$Longitude&tz=$TimeZone&dst=$DST > $ProjectDir$JSONFile" | log_to_noaa

printf "Today's Moon Info:" | log_to_noaa
MoonCurrentPhase=$(jq -r .properties.data.curphase $ProjectDir$JSONFile)
printf "Current Phase: $MoonCurrentPhase" | log_to_noaa

MoonIllumination=$(jq -r .properties.data.fracillum $ProjectDir$JSONFile)
printf "Illumination: $MoonIllumination%" | log_to_noaa

MoonClosestPhase=$(jq -r .properties.data.closestphase.phase $ProjectDir$JSONFile)
MoonClosestPhaseDay=$(jq -r .properties.data.closestphase.day $ProjectDir$JSONFile)
MoonClosestPhaseMonth=$(jq -r .properties.data.closestphase.month $ProjectDir$JSONFile)
MoonClosestPhaseYear=$(jq -r .properties.data.closestphase.year $ProjectDir$JSONFile)
printf "Closest Phase: ""$MoonClosestPhase" $MoonClosestPhaseYear"-"$MoonClosestPhaseMonth"-"$MoonClosestPhaseDay | log_to_noaa

MoonRise=$(jq -r .properties.data.moondata[0].phen $ProjectDir$JSONFile)
MoonRiseTime=$(jq -r .properties.data.moondata[0].time $ProjectDir$JSONFile)
printf "$MoonRise: $MoonRiseTime" | log_to_noaa

MoonUpperTransit=$(jq -r .properties.data.moondata[1].phen $ProjectDir$JSONFile)
MoonUpperTransitTime=$(jq -r .properties.data.moondata[1].time $ProjectDir$JSONFile)
printf "$MoonUpperTransit: $MoonUpperTransitTime" | log_to_noaa

MoonSet=$(jq -r .properties.data.moondata[2].phen $ProjectDir$JSONFile)
MoonSetTime=$(jq -r .properties.data.moondata[2].time $ProjectDir$JSONFile)
printf "$MoonSet: $MoonSetTime" | log_to_noaa

printf "Today's Sun Info:" | log_to_noaa
SunBeginCivilTwilight=$(jq -r .properties.data.sundata[0].phen $ProjectDir$JSONFile)
SunBeginCivilTwilightTime=$(jq -r .properties.data.sundata[0].time $ProjectDir$JSONFile)
printf "$SunBeginCivilTwilight: $SunBeginCivilTwilightTime" | log_to_noaa

SunRise=$(jq -r .properties.data.sundata[1].phen $ProjectDir$JSONFile)
SunRiseTime=$(jq -r .properties.data.sundata[1].time $ProjectDir$JSONFile)
printf "$SunRise: $SunRiseTime" | log_to_noaa

SunUpperTransit=$(jq -r .properties.data.sundata[2].phen $ProjectDir$JSONFile)
SunUpperTransitTime=$(jq -r .properties.data.sundata[2].time $ProjectDir$JSONFile)
printf "$SunUpperTransit: $SunUpperTransitTime" | log_to_noaa

SunSet=$(jq -r .properties.data.sundata[3].phen $ProjectDir$JSONFile)
SunSetTime=$(jq -r .properties.data.sundata[3].time $ProjectDir$JSONFile)
printf "$SunSet: $SunSetTime" | log_to_noaa

SunEndCivilTwilight=$(jq -r .properties.data.sundata[4].phen $ProjectDir$JSONFile)
SunEndCivilTwilightTime=$(jq -r .properties.data.sundata[4].time $ProjectDir$JSONFile)
printf "$SunEndCivilTwilight: $SunEndCivilTwilightTime" | log_to_noaa

WxReport=""
WxReport+=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\n'"Today's Moon Info:"
WxReport+=$'\n'"Current Phase:""$MoonCurrentPhase"
WxReport+=$'\n'"Illumination:""$MoonIllumination%"
WxReport+=$'\n'"Closest Phase:""$MoonClosestPhase"$" "$MoonClosestPhaseYear"-"$MoonClosestPhaseMonth"-"$MoonClosestPhaseDay
WxReport+=$'\n'"Rise:"$MoonRiseTime
WxReport+=$'\n'"Upper Transit:"$MoonUpperTransitTime
WxReport+=$'\n'"Set:"$MoonSetTime
WxReport+=$'\n📍'$NodeLocation

printf "WxReport: $WxReport" | log_to_noaa

# check how long the message is
WxReportLength=${#WxReport}
printf "WxReportLength: $WxReportLength" | log_to_noaa

python -m venv ~/src/venv && source ~/src/venv/bin/activate;

meshtastic --ch-index $Channel --sendtext "$WxReport" | log_to_noaa

WxReport=""
WxReport+=$UserStationId$' - '$(date '+%H:%M:%S')
WxReport+=$'\n'"Today's Sun Info:"
WxReport+=$'\n'"Begin Civil Twilight:"$SunBeginCivilTwilightTime
WxReport+=$'\n'"Rise:"$SunRiseTime
WxReport+=$'\n'"Upper Transit:"$SunUpperTransitTime
WxReport+=$'\n'"Set:"$SunSetTime
WxReport+=$'\n'"End Civil Twilight:"$SunEndCivilTwilightTime
WxReport+=$'\n📍'$NodeLocation

printf "WxReport: $WxReport" | log_to_noaa

# check how long the message is
WxReportLength=${#WxReport}
printf "WxReportLength: $WxReportLength" | log_to_noaa

meshtastic --ch-index $Channel --sendtext "$WxReport" | log_to_noaa

End=$(date '+%Y-%m-%d %H:%M:%S')
printf "Script Begin: $Begin" | log_to_noaa
printf "Script   End: $End" | log_to_noaa
printf "+------------------------------------+" | log_to_noaa
printf "|       END NAVY SUN MOON SH LOG     |" | log_to_noaa
printf "+------------------------------------+" | log_to_noaa
