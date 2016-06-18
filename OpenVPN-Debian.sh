#!/bin/bash

printf "Installing OpenVPN and Easy-RSA\n"
printf "_________________________________________________________________\n"
apt-get update
apt-get install -y openvpn easy-rsa
printf "_________________________________________________________________\n"

printf "\nUnzipping the sample server config file to use as a base.\n"
printf "_________________________________________________________________\n"
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
[ -f /etc/openvpn/server.conf ] && echo "Done - Moving on" || echo "Something messed up."
printf "_________________________________________________________________\n"
