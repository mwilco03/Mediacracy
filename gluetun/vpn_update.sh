#!/bin/bash
#script might need to be modified to point at docker-compose file 
#this in conjunction with vpn_update produces a list of servers with 
#lowest latency
# Define variables
gluetun_dir=$1 #"/home/plex/gluetun"
docker_compose_file="${gluetun_dir}/docker-compose.yml"
servers_json="${gluetun_dir}/servers.json"
gluetun_volume="${gluetun_dir}:/gluetun"

# Change directory to gluetun
cd "$gluetun_dir" || exit 1
docker run --rm -v "${gluetun_volume}" $docker_image format-servers -mullvad > /dev/null
chown plex:plex "${servers_json}"
# Parse and prioritize servers, and remove the trailing comma
new_hostnames=$(jq -r '.mullvad.servers[] | select(.vpn == "openvpn" and .country == "USA") | .hostname' "$servers_json" | \
    awk '{print $1".relays.mullvad.net"}' | \
    ./prioritizer.sh /dev/stdin 2>/dev/null | \
    sed 's/\.relays\.mullvad\.net//g' | head | tr "\n" "," | sed 's/,$//')

# Update docker-compose.yml with the new server hostnames using sed for in-place modification
sed -i -r "s/(SERVER_HOSTNAMES=).*/\1$new_hostnames/" "$docker_compose_file"

# Change ownership of the docker-compose.yml file
chown $USER:$USER "$docker_compose_file"

# Display the updated docker-compose.yml
cat "$docker_compose_file"
