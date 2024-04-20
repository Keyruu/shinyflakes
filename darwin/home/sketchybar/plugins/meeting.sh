#!/bin/bash

# Format for 'eventsFrom:START to:END' command
date_format="%Y-%m-%d %H:%M"

# Calculate start time in UTC (current time)
start_time_utc=$(date -u -v-30M +"$date_format")  # 1 hour ago in UTC to include ongoing events
end_time_utc=$(date -u -v+30M +"$date_format")    # 2 hours into the future in UTC to ensure upcoming events are included

# Get the current time in seconds since the epoch
current_time=$(date +%s)

# Initialize variables to store the closest event details
closest_event_title=""
closest_event_start_time=""
closest_event_diff=""

# Read the icalbuddy output line by line
while IFS= read -r line; do
  # Check if the line contains the event title
  if [[ $line =~ ^•.* ]]; then
    event_title=$(echo "$line" | cut -d'(' -f1 | sed 's/^• //')
  fi
  
  # Check if the line contains the event start time
  if [[ $line =~ ^[[:space:]]*today.* ]]; then
    event_start_time=$(echo "$line" | awk '{print $3}')
    event_end_time=$(echo "$line" | awk '{print $5}')
    
    # Convert the event start and end times to seconds since the epoch
    event_start_time_seconds=$(date -j -f "%H:%M" "$event_start_time" +%s)
    event_end_time_seconds=$(date -j -f "%H:%M" "$event_end_time" +%s)
    
    # Check if the event has already ended
    if ((current_time > event_end_time_seconds)); then
      continue
    fi
    
    # Calculate the absolute difference between the current time and the event start time
    event_diff=$((current_time - event_start_time_seconds))
    event_diff=${event_diff#-}
    
    # Check if this event is closer than the previously closest event
    if [[ -z $closest_event_diff || $event_diff -lt $closest_event_diff ]]; then
      closest_event_title="$event_title"
      closest_event_start_time="$event_start_time"
      closest_event_diff="$event_diff"
    fi
  fi
done <<< "$(icalbuddy -nc -li 10 eventsFrom:"$start_time_utc" to:"$end_time_utc")"

# Print the closest event details
if [[ -z $closest_event_title ]]; then
  sketchybar -m --set meeting drawing=off
  exit 0
fi

MEETING="$closest_event_start_time $closest_event_title"

# if meeting is longer than 25 characters, truncate it with ellipsis
if [ ${#MEETING} -gt 25 ]; then
  MEETING="${MEETING:0:25}…"
fi

sketchybar -m --set meeting label="$MEETING" \
              --set meeting drawing=on

