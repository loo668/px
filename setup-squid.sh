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
pid_filename /run/squid/squid.pid

http_access allow all

cache deny all
access_log stdio:/var/log/squid/access.log
EOF

squid -k parse -f "$config_file"

if [[ -f ${SQUID_CONFIG} ]]; then
    cp -a "$SQUID_CONFIG" "$backup_file"
fi
install -o root -g root -m 0644 "$config_file" "$SQUID_CONFIG"

if [[ -d /run/systemd/system ]] && systemctl is-system-running >/dev/null 2>&1; then
    systemctl enable squid
    systemctl restart squid
else
    install -d -o proxy -g proxy -m 0755 /run/squid
    squid -k shutdown -f "$SQUID_CONFIG" >/dev/null 2>&1 || true
    for _ in {1..10}; do
        [[ ! -f /run/squid/squid.pid ]] && break
        sleep 1
    done
    squid -sYC -f "$SQUID_CONFIG"
fi

listening=false
for _ in {1..10}; do
    if ss -lnt | awk '{print $4}' | grep -q ":${SQUID_PORT}$"; then
        listening=true
        break
    fi
    sleep 1
done

if [[ $listening != true ]]; then
    echo "Squid is not listening on port ${SQUID_PORT}." >&2
    if [[ -d /run/systemd/system ]]; then
        systemctl --no-pager --full status squid
    else
        squid -k parse -f "$SQUID_CONFIG"
    fi
    exit 1
fi

if [[ -d /run/systemd/system ]]; then
    systemctl --no-pager --full status squid
else
    ps -o pid,user,cmd -C squid
fi
echo "Squid is listening on 0.0.0.0:${SQUID_PORT}."