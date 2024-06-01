#!/bin/bash

# Read from stdin if no file is provided as input
if [[ -t 0 ]]; then
    echo "Error: No input provided."
    exit 1
fi

# Temporary file to store results
temp_results=$(mktemp)

# Read each host from stdin and test latency
while read -r host; do
    if [ -n "$host" ]; then
        # Use ping to test the host. Adjust -c for count and -W for timeout.
        latency=$(ping -c 4 -W 2 "$host" | grep 'avg' | awk -F '/' '{print $5}')
        if [ -n "$latency" ]; then
            echo "$latency $host" >> "$temp_results"
        else
            echo "9999 $host" >> "$temp_results"  # Use a high latency for unreachable hosts
        fi
    fi
done

# Sort the results by latency (numerical sort)
sort -n "$temp_results" | awk '{print $2}'

# Remove the temporary file
rm "$temp_results"
