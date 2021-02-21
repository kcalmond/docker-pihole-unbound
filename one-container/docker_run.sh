#!/bin/bash

# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md

PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }

# Note: ServerIP should be replaced with your external ip.
docker run -d \
    --name pihole_unbound \
    -p 53:53/tcp -p 53:53/udp \
    -p 80:80 \
    -p 443:443 \
    -e TZ="America/Los_Angeles" \
    -v "${PIHOLE_BASE}/etc-pihole/:/etc/pihole/" \
    -v "${PIHOLE_BASE}/etc-dnsmasq.d/:/etc/dnsmasq.d/" \
    -e DNS1=127.0.0.1#5335 \
    -e DNS2=127.0.0.1#5335 \
    -e DNSSEC=true \
    --restart=unless-stopped \
    --hostname testpihole.almond.lan \
    -e VIRTUAL_HOST="testpihole.almond.lan" \
    -e PROXY_LOCATION="testpihole.almond.lan" \
    -e ServerIP="127.0.0.1" \
    -e REV_SERVER=true \
    -e REV_SERVER_DOMAIN="almond.lan" \
    -e REV_SERVER_TARGET="192.168.0.1" \
    -e REV_SERVER_CIDR="192.168.0.0/16" \
    cbcrowe/pihole-unbound:latest

printf 'Starting up pihole container '
for i in $(seq 1 20); do
    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole_unbound)" == "healthy" ] ; then
        printf ' OK'
        echo -e "\n$(docker logs pihole 2> /dev/null | grep 'password:') for your pi-hole: https://${IP}/admin/"
        exit 0
    else
        sleep 3
        printf '.'
    fi

    if [ $i -eq 20 ] ; then
        echo -e "\nTimed out waiting for Pi-hole and Unbound to start, consult your container logs for more info (\`docker logs pihole_unbound\`)"
        exit 1
    fi
done;
