#!/usr/bin/env bash

set -Eeuo pipefail

readonly SQUID_CONFIG='/etc/squid/squid.conf'
readonly SQUID_PORT='18889'

if [[ ${EUID} -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y squid

config_file=$(mktemp)
backup_file="${SQUID_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
trap 'rm -f "$config_file"' EXIT

cat >"$config_file" <<EOF
http_port 0.0.0.0:${SQUID_PORT}

http_access allow all

cache deny all
access_log stdio:/var/log/squid/access.log
EOF

squid -k parse -f "$config_file"

if [[ -f ${SQUID_CONFIG} ]]; then
    cp -a "$SQUID_CONFIG" "$backup_file"
fi
install -o root -g root -m 0644 "$config_file" "$SQUID_CONFIG"

systemctl enable squid
systemctl restart squid

if ! ss -lnt '( sport = :'"$SQUID_PORT"' )' | tail -n +2 | grep -q .; then
    echo "Squid is not listening on port ${SQUID_PORT}." >&2
    systemctl --no-pager --full status squid
    exit 1
fi

systemctl --no-pager --full status squid
echo "Squid is listening on 0.0.0.0:${SQUID_PORT}."