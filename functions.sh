# ************************************************************************************************************************************
# copilot wrote this
# fetch_noaa_observation: fetch latest NOAA observation for a station and write to a JSON file.
# Default station: KNYC
# Default output: mesh_wx_NOAA/noaa_observations_latest.json
#
# Usage:
#   fetch_noaa_latest                # uses KNYC and mesh_wx_NOAA/noaa_observations_latest.json
#   fetch_noaa_latest KNYC /tmp/out.json

fetch_noaa_latest() {
  local station="${1:-KNYC}"
  local out="${2:-mesh_wx_NOAA/noaa_observations_latest.json}"
  local url="https://api.weather.gov/stations/${station}/observations/latest"
  local ua="PizzaDeliveryDude (https://github.com/PizzaDeliveryDude)"
  local tmp

  # create tmp file and ensure output directory exists
  tmp="$(mktemp "$(basename "$out").XXXXXX")" || tmp="$(mktemp)"
  mkdir -p "$(dirname "$out")" || {
    echo "fetch_noaa_latest Error: failed to create directory for $out" >&2
    rm -f "$tmp"
    return 1
  }

  # fetch (use a User-Agent as required by api.weather.gov)
  if ! curl -sfS --compressed \
       -H "Accept: application/geo+json" \
       -H "User-Agent: ${ua}" \
       "$url" -o "$tmp"; then
    echo "fetch_noaa_latest Error: failed to fetch $url" >&2
    rm -f "$tmp"
    return 2
  fi

  # validate JSON if possible (jq preferred, fallback to python3)
  if command -v jq >/dev/null 2>&1; then
    if ! jq -e . "$tmp" >/dev/null 2>&1; then
      echo "fetch_noaa_latest Error: received invalid JSON" >&2
      rm -f "$tmp"
      return 3
    fi
  else
    if command -v python3 >/dev/null 2>&1; then
      if ! python3 -m json.tool <"$tmp" >/dev/null 2>&1; then
        echo "fetch_noaa_latest Error: received invalid JSON (python validation failed)" >&2
        rm -f "$tmp"
        return 3
      fi
    else
      # no validator available; continue but warn
      echo "fetch_noaa_latest Warning: jq or python3 not available; skipping JSON validation" >&2
    fi
  fi

  # Only replace the output file if the content changed
  if [ -f "$out" ] && cmp -s "$tmp" "$out"; then
    echo "fetch_noaa_latest No changes: $out unchanged."
    rm -f "$tmp"
    return 0
  fi

  mv -f "$tmp" "$out" && echo "fetch_noaa_latest Updated: $out" || { echo "Error: failed to move $tmp to $out" >&2; rm -f "$tmp"; return 4; }
}
# ************************************************************************************************************************************
# copolit wrote this
# Bash function to GET NOAA forecast and save to mesh_wx_NOAA/noaa_location_forecast.json
#
# Note: NOAA API requests are expected to include a descriptive User-Agent.
# Replace the contact info in USER_AGENT if you want to include an email or other contact.

USER_AGENT="PizzaDeliveryDude (script)"

fetch_noaa_forecast() {
#KNYC OKX/34,37
#KLGB SGX/32,67
#  local url="https://api.weather.gov/gridpoints/SGX/32,67/forecast"
  local url="${1:-https://api.weather.gov/gridpoints/SGX/32,67/forecast}"


  local station="${1:-KNYC}"

  local out_path="mesh_wx_NOAA/noaa_location_forecast.json"
  local tmp
  local retries=5
  local attempt=0
  local wait_sec=2

  # Ensure output directory exists
  mkdir -p "$(dirname "$out_path")"

  tmp="$(mktemp)" || { echo "Failed to create temp file" >&2; return 1; }

  while :; do
    attempt=$((attempt + 1))
    echo "Fetching NOAA forecast (attempt $attempt)..."

    # Use -f to make curl exit non‑zero on HTTP >=400, -sS for silent but show errors
    if curl -sS -f \
      -H "Accept: application/ld+json, application/json" \
      -H "User-Agent: $USER_AGENT" \
      "$url" -o "$tmp"; then

      # If jq is available, validate (and pretty-print) JSON before saving
      if command -v jq >/dev/null 2>&1; then
        if jq empty "$tmp" >/dev/null 2>&1; then
          jq . "$tmp" > "$out_path"
          rm -f "$tmp"
          echo "Forecast saved to $out_path"
          return 0
        else
          echo "Error: received invalid JSON" >&2
          rm -f "$tmp"
          return 2
        fi
      else
        # No jq: move as-is
        mv "$tmp" "$out_path"
        echo "Forecast saved to $out_path (jq not installed; file not pretty-printed)"
        return 0
      fi

    else
      # curl failed
      status=$?
      echo "Request failed (curl exit $status)." >&2
      if [ "$attempt" -ge "$retries" ]; then
        echo "Failed after $attempt attempts. Giving up." >&2
        rm -f "$tmp"
        return $status
      fi
      echo "Retrying in $wait_sec seconds..." >&2
      sleep "$wait_sec"
      wait_sec=$((wait_sec * 2))
    fi
  done
}

# If this file is executed (not sourced), run the function once.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_noaa_forecast
fi





# ************************************************************************************************************************************
# copilot wrote this
# converts degrees celsius to fahrenheit

c_to_f() {
  local input="${1:-}"

  if [[ -z $input ]]; then
    echo "Usage: c_to_f <temp[C]>" >&2
    return 1
  fi

  # normalize: remove degree symbols and whitespace, strip trailing 'c' or 'C'
  local s="${input//°/}"
  s="${s//º/}"
  s="${s//[[:space:]]/}"
  s="${s%c}"
  s="${s%C}"

  # validate numeric (allow optional sign and decimal point)
  if ! [[ $s =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
    echo "Invalid temperature: $input" >&2
    return 2
  fi

  # compute and round to nearest whole degree using awk's formatting
  local f
  f=$(awk -v c="$s" 'BEGIN { printf "%.0f", c * 9/5 + 32 }')

  #printf "%s°F\n" "$f"
  printf "%s" "$f"
}

# ************************************************************************************************************************************
# copilot wrote this
# usage: 
#   wind_dir_name <degrees>

wind_dir_name() {
  local deg="$1"

  # validate integer input
  if ! [[ "$deg" =~ ^-?[0-9]+$ ]]; then
    printf 'wind_dir_name Invalid input: not an integer\n' >&2
    return 1
  fi

  # normalize to 0..359
  deg=$(( (deg % 360 + 360) % 360 ))

  # use tenths of degrees to avoid floating point (0..3590)
  local deg10=$((deg * 10))

  if   (( deg10 >= 3375 || deg10 < 225 )); then printf 'N'
  elif (( deg10 >= 225  && deg10 <  675 )); then printf 'NE'
  elif (( deg10 >= 675  && deg10 < 1125 )); then printf 'E'
  elif (( deg10 >= 1125 && deg10 < 1575 )); then printf 'SE'
  elif (( deg10 >= 1575 && deg10 < 2025 )); then printf 'S'
  elif (( deg10 >= 2025 && deg10 < 2475 )); then printf 'SW'
  elif (( deg10 >= 2475 && deg10 < 2925 )); then printf 'W'
  elif (( deg10 >= 2925 && deg10 < 3375 )); then printf 'NW'
  else
    # should never happen
    printf 'Unknown\n' >&2
    return 2
  fi
}

# ************************************************************************************************************************************
# copilot wrote this
# Function: kph_to_mph <kilometers_per_hour>
# - Converts kilometers/hour to miles/hour
# - Rounds to the nearest whole number
# - If input is empty or numeric 0, prints "calm"

kph_to_mph() {
  local kph="$1"

  # If no argument provided or empty
  if [[ -z "$kph" ]]; then
    printf 'calm'
    return 0
  fi

  # Normalize common forms of zero (0, 0.0, 0.00)
  # And validate numeric input (allow optional leading - for completeness)
  if ! [[ "$kph" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    # non-numeric input -> treat as calm per safety (change if you prefer an error)
    printf 'calm'
    return 0
  fi

  # If numeric value is exactly zero -> calm
  # Use awk to check numeric value (handles decimals)
  if awk -v v="$kph" 'BEGIN { if (v+0 == 0) exit 0; exit 1 }'; then
    printf 'calm'
    return 0
  fi

  # Convert KPH to MPH (1 mile = 1.609344 km) and round to nearest whole number
  local mph
  mph=$(awk -v k="$kph" 'BEGIN { printf "%.0f", k / 1.609344 }')

  printf '%s mph' "$mph"
}

# Examples:
# echo "$(kph_to_mph 100)"   # -> 62
# echo "$(kph_to_mph 0)"     # -> calm
# echo "$(kph_to_mph 5.5)"   # -> 3
# echo "$(kph_to_mph)"       # -> calm
