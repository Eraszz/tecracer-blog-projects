#!/bin/bash

#sudo sed -i 's@nameserver ${dns_server_ip}@nameserver ${amazon_provided_dns}@g' /etc/resolv.conf

sudo yum update -y
sudo yum install bind bind-utils -y
sudo yum install telnet -y

sudo systemctl enable named
sudo systemctl start named

sudo tee /etc/named.conf <<EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
        listen-on port 53 { 127.0.0.1; ${dns_server_ip}; };
        //listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { localhost; ${on_premises_cidr}; ${aws_site_cidr}; };

        forwarders      { ${amazon_provided_dns}; };
        
        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-enable no;
        dnssec-validation no;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

//zone "." IN {
//        type hint;
//        file "named.ca";
//};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

//forward zone
zone "${local_domain_name}" IN {
     type master;
     file "${local_domain_name}.db";
     allow-update { none; };
};

//reverse zone
zone "128.0.10.in-addr.arpa" IN {
     type master;
     file "${local_domain_name}.rev";
     allow-update { none; };
};

//forward zone to AWS
//zone "${aws_site_domain_name}" {
//    type forward;
//    forward only;
//    forwarders { ;};
//};
EOF

sudo tee -a /var/named/${local_domain_name}.db <<EOF
\$TTL 86400
@   IN  SOA     ns1.${local_domain_name}. root.${local_domain_name}. (
                                              3           ;Serial
                                              3600        ;Refresh
                                              1800        ;Retry
                                              604800      ;Expire
                                              86400       ;Minimum TTL
)

;Name Server Information
@       IN  NS      ns1.${local_domain_name}.

;IP address of Name Server
ns1       IN  A       ${dns_server_ip}

;A - Record HostName To Ip Address
server     IN  A       ${server_ip}
EOF


sudo tee -a /var/named/${local_domain_name}.rev <<EOF
\$TTL 86400
@   IN  SOA     ns1.${local_domain_name}. root.${local_domain_name}. (
                                       3           ;Serial
                                       3600        ;Refresh
                                       1800        ;Retry
                                       604800      ;Expire
                                       86400       ;Minimum TTL
)

;Name Server Information
@         IN      NS         ns1.${local_domain_name}.

;Reverse lookup for Name Server
${split(".", dns_server_ip)[3]}       IN  PTR     ns1.${local_domain_name}.

;PTR Record IP address to HostName
${split(".", server_ip)[3]}       IN  PTR     server.${local_domain_name}.
EOF

sudo systemctl restart named

# named-checkconf /etc/named.conf
# named-checkzone on-premises.com /var/named/on-premises.com.db
# named-checkzone 128.0.10.in-addr.arpa /var/named/on-premises.com.rev
# systemctl restart named
# rndc reload