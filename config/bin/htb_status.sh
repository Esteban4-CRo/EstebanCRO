#!/usr/bin/env bash
ip=$(/usr/sbin/ifconfig tun0 2>/dev/null | grep "inet " | awk '{print $2}')
icon=$(printf '\xef\x84\xb2')
if [ -n "$ip" ]; then
  echo "%{F#1b8f3e}$icon%{F#000000} $ip"
else
  echo "%{F#e51d0b}$icon%{F#000000} Disconnected"
fi
