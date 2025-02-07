apt update -y
apt install -y curl
curl -sL https://api.github.com/repos/community-scripts/ProxmoxVE/contents/ct/ | grep raw | \
grep -E '(plex|petio|sabnzbd|sonarr|radarr|qbittorrent|prowlarr)' | \
cut -d'\"' -f4
