#!/bin/bash

printf "\nInstalling OpenVPN and Easy-RSA\n\n"
apt-get update
apt-get install -y openvpn easy-rsa
printf "_________________________________________________________________\n"

printf "\nUnzipping the sample server config file to use as a base.\n\n"
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
[ -f /etc/openvpn/server.conf ] && echo "Done - Moving on" || echo "Something messed up."
printf "_________________________________________________________________\n"

printf "\nChanging Initial Server Settings.\n\n"
printf "Changing Encryption Level: 'dh dh1024.pem' -> 'dh dh2048.pem'\n"
sed -i 's/dh dh1024.pem/dh dh2048.pem/g' /etc/openvpn/server.conf
printf "Allowing Web Traffic Forwarding\n"
sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
printf "Setting Clients to Use OpenDNS when possible\n"
sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/g' /etc/openvpn/server.conf
sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/g' /etc/openvpn/server.conf
printf "Setting Server Permissions\n"
sed -i 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
printf "_________________________________________________________________\n"



