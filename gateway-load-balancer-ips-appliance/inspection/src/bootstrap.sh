#!/bin/bash

set -e

############################
# INSTALL PACKAGES         #
############################

sudo apt update
sudo apt upgrade -y
sudo apt install -y unzip
sudo apt install -y jq
sudo apt install -y apache2
sudo apt-get -y install libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0

sudo apt-get -y install git binutils rustc cargo pkg-config libssl-dev
sudo git clone https://github.com/aws/efs-utils
cd /efs-utils
sudo ./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
cd ..

sudo echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
sudo echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get -y install iptables-persistent

############################
# WEBSERVER FOR HEALHCHECKS#
############################

sudo systemctl enable apache2
sudo echo "<html><head><title>Healthy</title></head></html>" | sudo tee /var/www/html/index.html
sudo systemctl start apache2

############################
# AWS CLI CONFIGURATION    #
############################

sudo curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

############################
# GET VALUES               #
############################

# Define variables
TOKEN=`sudo curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
instance_identity=$(sudo curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document)
instance_ip=$(echo "$instance_identity" | jq -r '.privateIp')
instance_id=$(echo "$instance_identity" | jq -r '.instanceId')
instance_interface_name=$(ip route get 1 | grep -o 'dev\s\S*' | awk '{print $2}')

############################
# EFS CONFIGURATION        #
############################

sudo mkdir -p /mnt/efs
sudo mount -t efs -o tls,iam ${efs_id}:/ /mnt/efs
sudo mkdir -p /mnt/efs/$instance_id/suricata
sudo ln -s /mnt/efs/$instance_id/suricata /var/log/
sudo echo "${efs_id}:/ /mnt/efs efs defaults,_netdev,tls,iam 0 0" | sudo tee -a /etc/fstab

##########################
# IPTABLES CONFIGURATION #
##########################

# Enable IP Forwarding:
sudo sysctl -w net.ipv4.ip_forward=1

# Flush the nat and mangle tables, flush all chains (-F), and delete all non-default chains (-X):
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

# Set the default policies for each of the built-in chains to ACCEPT:
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Set a punt to Suricata via NFQUEUE
sudo iptables -I FORWARD -j NFQUEUE --queue-num 0

# Configure nat table to hairpin traffic back to GWLB. Supports cross zone LB.
for i in $(aws --region ${aws_region} ec2 describe-network-interfaces --filters Name=vpc-id,Values=${vpc_id} --query 'NetworkInterfaces[?InterfaceType==`gateway_load_balancer`].PrivateIpAddress' --output text); do 
    sudo iptables -t nat -A PREROUTING -p udp -s $i -d $instance_ip -i $instance_interface_name -j DNAT --to-destination $i:6081
    sudo iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $i -d $i -o $instance_interface_name -j MASQUERADE
done

# Save iptables:
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

############################
# CLOUDWATCH CONFIGURATION #
############################

sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Specify the SSM parameter name for the CloudWatch Agent Config
PARAM_NAME=${parameter_store_config_file_name}
CLOUDWATCH_CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/bin/config.json"
PARAM_VALUE=$(aws ssm get-parameter --name "$PARAM_NAME" --query "Parameter.Value" --output text)

if [ -z "$PARAM_VALUE" ]; then
    echo "Failed to retrieve parameter value for $PARAM_NAME"
    exit 1
fi

sudo echo "$PARAM_VALUE" > "$CLOUDWATCH_CONFIG_PATH"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

############################
# SURICATA CONFIGURATION   #
############################

sudo apt install -y suricata

sudo sed -i "s/interface: eth0/interface: $instance_interface_name/g" /etc/suricata/suricata.yaml
sudo echo -e "\ndetect-engine:\n  - rule-reload: true" >> /etc/suricata/suricata.yaml
sudo touch /var/lib/suricata/rules/${custom_rule_file_name}
sudo sed -i "/^rule-files:/a \ \ - ${custom_rule_file_name}" /etc/suricata/suricata.yaml
sudo sed -i "s/eth0/$instance_interface_name/g" /etc/default/suricata

sudo cat <<EOF > /etc/systemd/system/suricata.service
# Define the Suricata systemd unit
[Unit]
Description=Suricata IDS/IPS
After=network.target

# Specify the Suricata binary path, the configuration files location, and the network interface
[Service]
ExecStart=/usr/bin/suricata -c /etc/suricata/suricata.yaml -q 0
[Install]
WantedBy=default.target
EOF

sudo systemctl enable suricata.service
sudo suricata-update
sudo systemctl start suricata.service