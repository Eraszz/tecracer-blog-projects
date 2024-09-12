#!/bin/bash

set -e

############################
# INSTALL PACKAGES         #
############################

sudo apt update
sudo apt upgrade -y
sudo apt install unzip jq apache2 curl gnupg2 wget -y

sudo apt-get -y install git binutils rustc cargo pkg-config libssl-dev
sudo git clone https://github.com/aws/efs-utils
cd /efs-utils
sudo ./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
cd ..

############################
# INSTALL ZEEK             #
############################

sudo echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
sudo curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update -y
echo "postfix postfix/main_mailer_type select No configuration" | sudo debconf-set-selections
sudo apt install -y postfix
sudo apt install zeek -y
sudo echo "export PATH=$PATH:/opt/zeek/bin" >> ~/.bashrc
export PATH=$PATH:/opt/zeek/bin

############################
# WEBSERVER FOR HEALHCHECKS#
############################

sudo systemctl enable apache2
sudo echo "<html><head><title>Healthy</title></head></html>" | sudo tee /var/www/html/index.html
sudo systemctl start apache2

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

sudo rmdir /opt/zeek/logs/
sudo mkdir -p /mnt/efs
sudo mount -t efs -o tls,iam ${efs_id}:/ /mnt/efs
sudo mkdir -p /mnt/efs/$instance_id/opt/zeek/logs/
sudo ln -s /mnt/efs/$instance_id/opt/zeek/logs/ /opt/zeek/
sudo echo "${efs_id}:/ /mnt/efs efs defaults,_netdev,tls,iam 0 0" | sudo tee -a /etc/fstab

############################
# CONFIGURE ZEEK           #
############################

sudo cat <<EOF > /opt/zeek/etc/node.cfg
[zeek-logger]
type=logger
host=$instance_ip
#
[zeek-manager]
type=manager
host=$instance_ip
#
[zeek-proxy]
type=proxy
host=$instance_ip
#
[zeek-worker]
type=worker
host=$instance_ip
interface=$instance_interface_name
EOF

echo "@load policy/tuning/json-logs.zeek" | sudo tee -a /opt/zeek/share/zeek/site/local.zeek > /dev/null
zeekctl deploy

############################
# FILEBEAT CONFIGURAITON   #
############################

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.1-amd64.deb
sudo dpkg -i filebeat-8.15.1-amd64.deb
sudo filebeat modules enable zeek

cat <<EOF > /etc/filebeat/filebeat.yml
###################### Filebeat Configuration Example #########################

# This file is an example configuration file highlighting only the most common
# options. The filebeat.reference.yml file from the same directory contains all the
# supported options with more comments. You can use it as a reference.
#
# You can find the full configuration reference here:
# https://www.elastic.co/guide/en/beats/filebeat/index.html

# For more available modules and options, please see the filebeat.reference.yml sample
# configuration file.

# ============================== Filebeat inputs ===============================

filebeat.inputs:

# Each - is an input. Most options can be set at the input level, so
# you can use different inputs for various configurations.
# Below are the input-specific configurations.

# filestream is an input for collecting log messages from files.
- type: filestream

  # Unique ID among all inputs, an ID is required.
  id: my-filestream-id

  # Change to true to enable this input configuration.
  enabled: true

  # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - /opt/zeek/logs/current/*.log
    #- c:\programdata\elasticsearch\logs\*

  # Exclude lines. A list of regular expressions to match. It drops the lines that are
  # matching any regular expression from the list.
  # Line filtering happens after the parsers pipeline. If you would like to filter lines
  # before parsers, use include_message parser.
  #exclude_lines: ['^DBG']

  # Include lines. A list of regular expressions to match. It exports the lines that are
  # matching any regular expression from the list.
  # Line filtering happens after the parsers pipeline. If you would like to filter lines
  # before parsers, use include_message parser.
  #include_lines: ['^ERR', '^WARN']

  # Exclude files. A list of regular expressions to match. Filebeat drops the files that are
  # matching any regular expression from the list. By default, no files are dropped.
  #prospector.scanner.exclude_files: ['.gz$']

  # Optional additional fields. These fields can be freely picked
  # to add additional information to the crawled log files for filtering
  #fields:
  #  level: debug
  #  review: 1

# ============================== Filebeat modules ==============================

filebeat.config.modules:
  # Glob pattern for configuration loading
  path: /etc/filebeat/modules.d/*.yml

  # Set to true to enable config reloading
  reload.enabled: false

  # Period on which files under path should be checked for changes
  #reload.period: 10s

# ================================== Outputs ===================================

# Configure what output to use when sending the data collected by the beat.

# ------------------------------ Logstash Output -------------------------------
output.logstash:
  # The Logstash hosts
  hosts: ["localhost:5044"]

  # Optional SSL. By default is off.
  # List of root certificates for HTTPS server verifications
  #ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  #ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  #ssl.key: "/etc/pki/client/cert.key"

# ================================= Processors =================================
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF

cat <<EOF > /etc/filebeat/modules.d/zeek.yml
# Module: zeek
# Docs: https://www.elastic.co/guide/en/beats/filebeat/main/filebeat-module-zeek.html

- module: zeek
  capture_loss:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/capture_loss.log"]
  connection:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/conn.log"]
  dce_rpc:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/dce_rpc.log"]
  dhcp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/dhcp.log"]
  dnp3:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/dnp3.log"]
  dns:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/dns.log"]
  dpd:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/dpd.log"]
  files:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/files.log"]
  ftp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/ftp.log"]
  http:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/http.log"]
  intel:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/intel.log"]
  irc:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/irc.log"]
  kerberos:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/kerberos.log"]
  modbus:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/modbus.log"]
  mysql:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/mysql.log"]
  notice:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/notice.log"]
  ntlm:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/ntlm.log"]
  ntp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/ntp.log"]
  ocsp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/oscp.log"]
  pe:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/pe.log"]
  radius:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/radius.log"]
  rdp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/rdp.log"]
  rfb:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/rfb.log"]
  signature:
    enabled: false
    var.paths: ["/opt/zeek/logs/current/signature.log"]
  sip:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/sip.log"]
  smb_cmd:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/smb_cmd.log"]
  smb_files:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/smb_files.log"]
  smb_mapping:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/smb_mapping.log"]
  smtp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/smtp.log"]
  snmp:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/snmp.log"]
  socks:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/socks.log"]
  ssh:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/ssh.log"]
  ssl:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/ssl.log"]
  stats:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/stats.log"]
  syslog:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/syslog.log"]
  traceroute:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/traceroute.log"]
  tunnel:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/tunnel.log"]
  weird:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/weird.log"]
  x509:
    enabled: true
    var.paths: ["/opt/zeek/logs/current/x509.log"]

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:
EOF
sudo systemctl start filebeat

############################
# LOGSTASH CONFIGURAITON   #
############################

sudo wget https://artifacts.opensearch.org/logstash/logstash-oss-with-opensearch-output-plugin-8.9.0-linux-x64.tar.gz
sudo tar -zxvf logstash-oss-with-opensearch-output-plugin-8.9.0-linux-x64.tar.gz
cd logstash-8.9.0
sudo bin/logstash-plugin install logstash-output-opensearch
sudo tee config/pipeline.conf > /dev/null <<EOF
input {
  beats {
    port => 5044
  }
}

output {
  opensearch {
    hosts => ["${opensearch_domain}"]
    auth_type => {
     type => 'aws_iam'
     region => "eu-central-1"
     aws_access_key_id => ''
     aws_secret_access_key => ''
    }
    index => "zeek-%%{+YYYY.MM.dd}"
  }
}
EOF
sudo bin/logstash -f config/pipeline.conf --config.reload.automatic
