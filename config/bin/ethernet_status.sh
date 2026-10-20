#!/usr/bin/env bash
ip=$(/usr/sbin/ifconfig eth0 2>/dev/null | grep "inet " | awk '{print $2}')
echo "%{F#1565c0}$(printf '\xef\x82\xac')%{F#000000} ${ip:-sin red}"
