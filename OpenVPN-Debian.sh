#!/bin/bash

printf "Installing OpenVPN and Easy-RSA\n"
printf "-----------------------------------------------------------------\n"
apt-get update
apt-get install -y openvpn easy-rsa
printf "-----------------------------------------------------------------\n"

printf "\nUnzipping the sample server config file to use as a base.\n"
printf "-----------------------------------------------------------------\n"
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
printf "-----------------------------------------------------------------\n"
