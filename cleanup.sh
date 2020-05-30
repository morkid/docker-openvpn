#!/bin/sh

rm -rf data/openvpn/pki data/openvpn/openvpn.conf data/openvpn/ovpn_env.sh data/openvpn/clients/*
find data/logs -type f -name *.log -delete
