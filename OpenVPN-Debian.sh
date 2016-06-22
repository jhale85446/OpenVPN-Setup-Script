#!/bin/bash

# This is a bash script used to set up OpenVPN on a Debian distro
# by Josh Hale https://github.com/jhale85446

# Default Values
traffic="udp"
port=1194
good=0
cipher=1
cipher_output="cipher BF-CBC        # Blowfish (default)"

function intro 
{
  printf "\nWelcome to OpenVPN Setup Script by Josh Hale\n"
  printf "This script will setup OpenVPN on your computer.\n\n"
}

function install_openvpn
{
  printf "\nInstalling OpenVPN and Easy-RSA\n\n"
  apt-get update
  apt-get install -y openvpn easy-rsa
  printf "_________________________________________________________________\n"
}

function install_ufw
{
  printf "\nInstalling UFW\n\n"
  apt-get install -y ufw
  printf "\n_________________________________________________________________\n"
}

function unpack_config
{
  printf "\nUnzipping the sample server config file to use as a base.\n\n"
  gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf

  if [ -f /etc/openvpn/server.conf ]; then
    printf "Done - Moving on\n"
  else
    printf "Something messed up. Exiting.\n"
    exit 1
  fi

  printf "_________________________________________________________________\n"
}

function init_setup
{
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
}

function select_traffic
{
  #Select the type of traffic TCP or UDP
  while [ "$traffic" == "" ]; do
    printf "Do you want to use UDP or TCP for VPN traffic?\n"
    printf "UDP is default. However, many firewalls block non-DNS UDP traffic\n"
    printf "TCP is recommended.\n\n"
    printf "1 for UDP\n"
    printf "2 for TCP\n"
    printf "\nSelect a traffic type: "
    read choice

    if [ ! -z ${choice// } ]; then
      if [ $choice -eq 1 ]; then
        printf "UDP traffic selected.\n"
        traffic="udp"
      elif [ $choice -eq 2 ]; then
        printf "TCP traffic selected.\n"
        traffic="tcp"
      else
        printf "Please enter either 1 or 2 to select UDP or TCP.\n\n"
      fi
    fi
  done

  printf "Setting VPN Traffic Type to $traffic\n"
  if [ "$traffic" == "udp" ]; then
    sed -i 's/^;proto udp/proto udp/g' /etc/openvpn/server.conf
    sed -i 's/^proto tcp/;proto tcp/g' /etc/openvpn/server.conf
  else
    sed -i 's/^proto udp/;proto udp/g' /etc/openvpn/server.conf
    sed -i 's/^;proto tcp/proto tcp/g' /etc/openvpn/server.conf
  fi
}

function select_port
{
  #Select the port to operate on
  while [ $good -eq 0 ]; do
    if [ "$traffic" == "UDP" ]; then
      printf "\nWhich port would you like to use? Default is port 1194. Many firewalls block non-DNS UDP traffic. DNS is on port 53.\n"
    else
      printf "\nWhich port would you like to use? Default is port 1194. Firewalls may block uncommon TCP ports. You may want to use one of these:\n"
      printf "HTTP: 80\n"
      printf "HTTPS: 443 (This is a good option if your local port 443 is not being used. It will look like https traffic to firewalls.)\n"
      printf "Default port is generally ok.\n"
    fi
    printf "\nPort: [Enter for 1194] "
    read choice

    if [ ! -z ${choice// } ]; then
      if [ $choice -ge 1 -a $choice -le 65535 ]; then
        port=$choice
        good=1
      fi
    else
       good=1
    fi
  done
  printf "Setting VPN Port to $port\n"
  sed -i "s/^port.*/port $port/g" /etc/openvpn/server.conf
}

function select_cipher
{
  #Select the cipher to use
  good=0
  while [ $good -eq 0 ]; do
    printf "\nWhich cipher do you want to use? Blowfish is default. However, most modern processors have AES built-in and it might be faster.\n\n"
    printf "1 for Blowfish CBC\n"
    printf "2 for AES-128 CBC\n"
    printf "3 for Triple-DES CBC (Not recommended!)\n"
    printf "\nCipher to use: "
    read choice

    if [ ! -z ${choice// } ]; then
      if [ $choice -eq 1 ]; then
        printf "Blowfish CBC Selected.\n"
        cipher=1
        cipher_output="cipher BF-CBC        # Blowfish (default)"
        good=1
      elif [ $choice -eq 2 ]; then
        printf "AES-128 CBC Selected.\n"
        cipher=2
        cipher_output="cipher AES-128-CBC   # AES"
        good=1
      elif [ $choice -eq 3 ]; then
        printf "Triple-DES CBC Selected.\n"
        cipher=3
        cipher_output="cipher DES-EDE3-CBC  # Triple-DES"
        good=1
      else
        printf "Please enter 1, 2, or 3 to select a cipher.\n\n"
      fi
    fi
  done

  if [ $cipher -eq 1 ]; then
    printf "Setting VPN Cipher to Blowfish\n"
    sed -i 's/^;cipher BF-CBC.*/cipher BF-CBC        # Blowfish (default)/g' /etc/openvpn/server.conf
    sed -i 's/^cipher AES-128-CBC.*/;cipher AES-128-CBC   # AES/g' /etc/openvpn/server.conf
    sed -i 's/^cipher DES-EDE3-CBC.*/;cipher DES-EDE3-CBC  # Triple-DES/g' /etc/openvpn/server.conf
  elif [ $cipher -eq 2 ]; then
    printf "Setting VPN Cipher to AES\n"
    sed -i 's/^cipher BF-CBC.*/;cipher BF-CBC        # Blowfish (default)/g' /etc/openvpn/server.conf
    sed -i 's/^;cipher AES-128-CBC.*/cipher AES-128-CBC   # AES/g' /etc/openvpn/server.conf
    sed -i 's/^cipher DES-EDE3-CBC.*/;cipher DES-EDE3-CBC  # Triple-DES/g' /etc/openvpn/server.conf
  else
    printf "Setting VPN Cipher to Triple-DES\n"
    sed -i 's/^cipher BF-CBC.*/;cipher BF-CBC        # Blowfish (default)/g' /etc/openvpn/server.conf
    sed -i 's/^cipher AES-128-CBC.*/;cipher AES-128-CBC   # AES/g' /etc/openvpn/server.conf
    sed -i 's/^;cipher DES-EDE3-CBC.*/cipher DES-EDE3-CBC  # Triple-DES/g' /etc/openvpn/server.conf
  fi
}

function add_routes
{
  # Add subnet routes to be pushed to the clients
  good=0
  add_subnets=0
  while [ $good -eq 0 ]; do
    printf "\nWould you like to push any routes to local (server side) subnets to the clients? [y or n] "
    read choice
    if [ "$choice" == "y" ]; then
      add_subnets=1
      good=1
    elif [ "$choice" == "n" ]; then
      good=1
    fi
  done

  subnet_count=0
  while [ $add_subnets -eq 1 ]; do
    good=0
    printf "\nPlease enter the subnet in the following format: IPv4subnet IPv4netmask\n"
    printf "This script will not check the validity of your entry so make sure it is correct before hitting enter!\n"
    printf "Example: 192.168.1.0 255.255.255.0\n"
    printf "\nSubnet [Press Enter to Abort Entry]: "
    read response

    if [ ! -z ${response// } ]; then  
      subnets[${subnet_count}]=$response
      (( subnet_count += 1 ))
    fi

    while [ $good -eq 0 ]; do
      printf "\nWould you like to push any additional routes to local (server side) subnets to the clients? [y or n] "
      read choice
      if [ "$choice" == "y" ]; then
        good=1
        add_subnets=1
      elif [ "$choice" == "n" ]; then
        good=1
        add_subnets=0
      fi
    done
  done

  if [ $subnet_count -gt 0 ]; then
    count=${#subnets[@]}
    for (( i=0;i<$count;i++)); do
      subnet_string="push \"route ${subnets[${i}]}\""
      printf "Adding Client Route to ${subnets[${i}]}\n"
      sed -i "/^# back to the OpenVPN server.*/a $subnet_string" /etc/openvpn/server.conf
    done
  fi
  printf "_________________________________________________________________\n"
}

function enable_packet_forward
{
  printf "\nEnabling Packet Forwarding\n"
  echo 1 > /proc/sys/net/ipv4/ip_forward
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
  printf "_________________________________________________________________\n"
}

function config_ufw
{
  printf "\nConfiguring UFW and OpenVPN\n"
  printf "\nThis script will open SSH and port $port/$traffic by default.\n"
  good=0
  add_exceptions=0
  while [ $good -eq 0 ]; do
    printf "\nWould you like to open any other ports? [y or n] "
    read choice
    if [ "$choice" == "y" ]; then
      add_exceptions=1
      good=1
    elif [ "$choice" == "n" ]; then
      good=1
    fi
  done

  exceptions_count=0
  while [ $add_exceptions -eq 1 ]; do
    good=0
    printf "\nPlease enter the port and protocol as follows port/protocol (lowercase)\n"
    printf "This script will not check the validity of your entry so make sure it is correct before hitting enter!\n"
    printf "Example: 80/tcp\n"
    printf "\nPort/Protocol [Press Enter to Abort Entry]: "
    read response

    if [ ! -z ${response// } ]; then  
      exceptions[${exceptions_count}]=$response
     (( exceptions_count += 1 ))
    fi

    while [ $good -eq 0 ]; do
      printf "\nWould you like to open any other ports? [y or n] "
      read choice
      if [ "$choice" == "y" ]; then
        good=1
        add_exceptions=1
      elif [ "$choice" == "n" ]; then
        good=1
        add_exceptions=0
      fi
    done
  done

  printf "\nAllowing SSH\n"
  ufw allow ssh
  printf "Allowing $port/$traffic\n"
  ufw allow $port/$traffic

  if [ $exceptions_count -gt 0 ]; then
    count=${#exceptions[@]}
    for (( i=0;i<$count;i++)); do
      printf "Allowing ${exceptions[${i}]}\n"
      ufw allow ${exceptions[${i}]}
    done
  fi
  printf "_________________________________________________________________\n"
}

function select_interface
{
  ifconfig
  printf "\nYou need to select an interface for OpenVPN to operate on.\n"
  printf "Make sure you look at the interface list above, not all distros use eth0 anymore!\n"
  printf "Enter the interface [enter for eth0]: "
  read interface

  if [ -z ${interface// } ]; then
    interface="eth0"
  fi

  printf "\nSetting up UFW to use interface $interface\n"

  printf "Changing Default Forward Policy to ACCEPT\n"
  sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

  printf "Adding OpenVPN Firewall Rules\n"
  sed -i "/^# Don't delete these required lines.*/i # START OPENVPN RULES" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i # NAT table rules" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i *nat" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i :POSTROUTING ACCEPT [0:0]" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i # Allow traffic from OpenVPN client to $interface" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i -A POSTROUTING -s 10.8.0.0/8 -o $interface -j MASQUERADE" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i COMMIT" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i # END OPENVPN RULES" /etc/ufw/before.rules
  sed -i "/^# Don't delete these required lines.*/i #" /etc/ufw/before.rules
  printf "_________________________________________________________________\n"
}

function enable_ufw
{
  printf "\nEnabling UFW\n\n"
  ufw enable
  printf "\n"
  ufw status
  printf "_________________________________________________________________\n"
}

function init_rsa_ca
{
  printf "\nSetting up Certificate Authority and RSA Keys\n"
  cp -r /usr/share/easy-rsa/ /etc/openvpn
  mkdir /etc/openvpn/easy-rsa/keys
  printf "\nNeed to get some information from you to set up your certificates...\n\n"

  dne=0
  while [ $dne -eq 0 ]; do
    #Country
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your Country [ie US]: "
      read country
      if [ ! -z ${country// } ]; then
        key_country="export KEY_COUNTRY=\"$country\""
        good=1
      fi
    done

    #State
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your Province or State [ie IA]: "
      read state
      if [ ! -z ${state// } ]; then
        key_state="export KEY_PROVINCE=\"$state\""
        good=1
      fi
    done

    #City
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your City [ie Ames]: "
      read city
      if [ ! -z ${city// } ]; then
        key_city="export KEY_CITY=\"$city\""
        good=1
      fi
    done

    #Organization
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your Organization [ie Evil Corp]: "
      read org
      if [ ! -z ${org// } ]; then
        key_org="export KEY_ORG=\"$org\""
        good=1
      fi
    done

    #email
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your Email Address [ie john@ecorp.com]: "
      read email
      if [ ! -z ${email// } ]; then
        key_email="export KEY_EMAIL=\"$email\""
        good=1
      fi
    done

    #OrganizationalUnit
    good=0
    while [ $good -eq 0 ]; do
      printf "Enter your Organizational Unit [ie Hacker Defense]: "
      read OU
      if [ ! -z ${OU// } ]; then
        key_ou="export KEY_OU=\"$OU\""
        good=1
      fi
    done

    printf "\nThis is the output that will be written into the RSA Vars file:\n\n"
    printf "$key_country\n"
    printf "$key_state\n"
    printf "$key_city\n"
    printf "$key_org\n"
    printf "$key_email\n"
    printf "$key_ou\n\n"

    good=0
    while [ $good -eq 0 ]; do
      printf "Is this information correct [y or n]: "
      read choice
      if [ ! -z ${choice// } ]; then
        if [ "$choice" == "y" ]; then
          good=1
          dne=1
        elif [ "$choice" == "n" ]; then
          good=1
        else
          good=0
        fi
      fi
    done
  done

  printf "Setting up file /etc/openvpn/easy-rsa/vars\n" 
  sed -i "s/^export KEY_COUNTRY.*/$key_country/g" /etc/openvpn/easy-rsa/vars
  sed -i "s/^export KEY_PROVINCE.*/$key_state/g" /etc/openvpn/easy-rsa/vars
  sed -i "s/^export KEY_CITY.*/$key_city/g" /etc/openvpn/easy-rsa/vars
  sed -i "s/^export KEY_ORG.*/$key_org/g" /etc/openvpn/easy-rsa/vars
  sed -i "s/^export KEY_EMAIL.*/$key_email/g" /etc/openvpn/easy-rsa/vars
  sed -i "s/^export KEY_OU.*/$key_ou/g" /etc/openvpn/easy-rsa/vars
  sed -i 's/^export KEY_NAME.*/export KEY_NAME="server"/g' /etc/openvpn/easy-rsa/vars
  printf "_________________________________________________________________\n"
}

function gen_dh
{
  printf "Generating Diffie-Helman parameters. This may take a while...\n\n"
  openssl dhparam -out /etc/openvpn/dh2048.pem 2048
  printf "\nDone... Moving on.\n"
  printf "_________________________________________________________________\n"
}

# Main Program

intro
#install_openvpn
unpack_config
init_setup
select_traffic
select_port
select_cipher
add_routes
enable_packet_forward

#install_ufw
#config_ufw
#select_interface
#enable_ufw

#init_rsa_ca
#gen_dh
exit 0




