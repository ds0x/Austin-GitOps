#!/bin/sh
# Sets Cloudflare DNS (1.1.1.1 / 1.0.0.1, plus IPv6) on every network service
# on this Mac. Runs as root from Fleet, either on demand or automatically when
# the "macOS - Cloudflare DNS in use" policy fails.
#
# Note: a connected VPN can still push its own DNS servers; this script
# doesn't change VPN settings.

DNS_SERVERS="1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001"

# List network services, skipping the header line and disabled services (*).
/usr/sbin/networksetup -listallnetworkservices | /usr/bin/tail -n +2 | while IFS= read -r service; do
  case "$service" in
    \**) continue ;;
  esac
  # shellcheck disable=SC2086 # DNS_SERVERS is meant to split into separate arguments
  if /usr/sbin/networksetup -setdnsservers "$service" $DNS_SERVERS; then
    echo "Set Cloudflare DNS on: $service"
  else
    echo "Couldn't set DNS on: $service"
  fi
done

# Clear cached lookups so the new servers are used right away.
/usr/bin/dscacheutil -flushcache
/usr/bin/killall -HUP mDNSResponder 2>/dev/null

echo "Current resolvers:"
/usr/sbin/scutil --dns | /usr/bin/awk '/nameserver\[/ {print "  " $3}' | /usr/bin/sort -u
exit 0
