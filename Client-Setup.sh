#!/bin/bash

# This is a bash script used to set up OpenVPN Clients
# by Josh Hale "sn0wfa11" https://github.com/sn0wfa11

add_clients=1
while [ $add_clients -eq 1 ]; do
  printf "\nPlease enter the name of the client: "
  read response

  if [ ! -z ${response// } ]; then  
    clientname=$response
  fi

  # Add a client
  printf "\nSetting up client $clientname.\n"
  cd /etc/openvpn/easy-rsa
  eval '. ./vars'
  eval ./build-key ${clientname}

  mkdir /etc/openvpn/clients/${clientname}
  cp /etc/openvpn/easy-rsa/keys/client.ovpn /etc/openvpn/clients/${clientname}
  cd /etc/openvpn/clients/${clientname}

  echo '<cert>' >> client.ovpn
  cat /etc/openvpn/easy-rsa/keys/${clientname}.crt >> client.ovpn
  echo '</cert>' >> client.ovpn

  echo '<key>' >> client.ovpn
  cat /etc/openvpn/easy-rsa/keys/${clientname}.key >> client.ovpn
  echo '</key>' >> client.ovpn

  printf "Client: $clientname has been created.\n\n"
  printf "The client.ovpn file for $clientname is localted at:\n"
  printf "/etc/openvpn/clients/$clientname\n\n"
  printf "This is a unified file with all the certificates needed. Copy this to the client for setup.\n"

  good=0
  while [ $good -eq 0 ]; do
    printf "\nWould you like to add any more clients? [y or n] "
    read choice
    if [ "$choice" == "y" ]; then
      good=1
      add_clients=1
    elif [ "$choice" == "n" ]; then
      good=1
      add_clients=0
    fi
  done
done
