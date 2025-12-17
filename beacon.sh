#!/bin/bash

# NOAA observations - latest
echo $(clear)

# setup
echo ""
echo " - - script setup"
Begin=$(date '+%Y-%m-%d %H:%M:%S')

Channel="${1:-0}"
Beacon='I send hourly reports on the nyme.sh weather channel - - Channel Name:Wx Key Size: 1 byte Key:WQ=='
echo ""
echo " - - send mesh_wx"
python -m venv ~/src/venv && source ~/src/venv/bin/activate;
echo "python stuff"

meshtastic --ch-index $Channel --sendtext "$Beacon"
#meshtastic --ch-index $Channel --sendtext "$Beacon">/dev/null 2>&1
echo "meshtastic stuff"

echo ""
echo " - - execution times"
End=$(date '+%Y-%m-%d %H:%M:%S')
echo $"Script Begin: "$Begin
echo $"Script   End: "$End
