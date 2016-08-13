#!/bin/sh

set -eu

add() {
  listen_port="$1"
  name="$2"
  public_key="$3"
  endpoint="$4"
  ip4="$5"
  ip6="$6"
  del "$@"
  ip link add dev "$name" type wireguard

  echo "$PRIVATE_KEY" | wg set "$name" \
    $([[ -n "$listen_port" ]] && echo "listen-port $listen_port") \
    private-key /dev/stdin \
    peer "$public_key" \
    allowed-ips "0.0.0.0/0,::/0" \
    $([[ -n "$endpoint" ]] && echo "endpoint $endpoint")

  ip link set dev "$name" up

  if [ -n "$OWN_IP4" ]; then
    if [ -n "$ip4" ]; then
      ip addr add "$OWN_IP4" dev "$name" peer "$ip4"
    else
      ip addr add "$OWN_IP4" dev "$name"
    fi
  fi
  if [ -n "$OWN_IP6" ]; then
    ip addr add "$OWN_IP6" dev "$name"
  fi
  if [ -n "$ip6" ]; then
    ip route add "$ip6" dev "$name"
  fi
}
del() {
  name="$2"
  if ip link | grep -q "$name"; then
    ip link del "$name"
  fi
}

case "${1:-}" in
start)
  peers add
  ;;
stop)
  peers del
  ;;
restart)
  peers del
  peers add
  ;;
*)
  echo "USAGE: $0 start|restart|stop" >&2
  exit 1
esac
