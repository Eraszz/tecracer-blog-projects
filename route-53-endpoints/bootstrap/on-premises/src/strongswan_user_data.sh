#!/bin/bash

sudo amazon-linux-extras install epel -y
sudo yum repolist
sudo yum update -y
sudo yum install strongswan -y
sudo systemctl enable strongswan

sudo tee /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1 
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.all.send_redirects = 0
EOF

sudo sysctl -p /etc/sysctl.conf

sudo tee /etc/strongswan/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file
# basic configuration

config setup
        charondebug="all"
        uniqueids=yes
        strictcrlpolicy=no

conn %default
        type=tunnel
        auto=start
        keyexchange=ikev2
        authby=psk
        aggressive=no
        ikelifetime=28800s
        lifetime=3600s
        margintime=270s
        rekey=yes
        rekeyfuzz=100%
        fragmentation=yes
        replay_window=1024
        dpddelay=30s
        dpdtimeout=120s
        dpdaction=restart
        ike=aes128-sha1-modp1024
        esp=aes128-sha1-modp1024
        keyingtries=%forever
        leftsubnet=${on_premises_network_cidr_range}
        rightsubnet=${aws_network_cidr_range}
        leftfirewall=yes
conn tunnel-1
        left=${on_premises_private_ip}
        leftid=${on_premises_peer_ip}
        right=${aws_network_peer_ip_1}
conn tunnel-2
        left=${on_premises_private_ip}
        leftid=${on_premises_peer_ip}
        right=${aws_network_peer_ip_2}
EOF

sudo tee /etc/strongswan/ipsec.secrets <<EOF

#------- Tunnel 1 ------- 

${on_premises_peer_ip} ${aws_network_peer_ip_1} : PSK "${vpn_tunnel1_preshared_key}"

#------- Tunnel 2 ------- 

${on_premises_peer_ip} ${aws_network_peer_ip_2} : PSK "${vpn_tunnel2_preshared_key}"
EOF


sudo strongswan restart
sudo strongswan up tunnel-1
sudo strongswan up tunnel-2