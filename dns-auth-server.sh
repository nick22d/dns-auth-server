#!/bin/bash
### Description: This script configures an authoritative DNS server
### Written by: Nicholas Doropoulos
### Version: 1

#=========#
# MAIN BODY
#=========#

# Update the software repositories
apt-get update -y

# Install the bind service
apt-get install bind9 bind9utils -y

# Create a 'zones' directory for easier management
mkdir /etc/bind/zones

# Create the zones in the /etc/bind/named.conf.local file
echo -e "zone \"mydomain.com\" IN { \ntype master; \nfile \"/etc/bind/zones/forward.mydomain.com\"; \nallow-query { any; }; \n}; \n \nzone \"1.1.10.in-addr.arpa\" IN { \ntype master; \nfile \"/etc/bind/zones/reverse.mydomain.com\"; \n};" >> /etc/bind/named.conf.local

# Create the DNS forward and reverse lookup zones
touch /etc/bind/zones/forward.mydomain.com /etc/bind/zones/reverse.mydomain.com

# Assign the correct permissions inside the bind directory
chown -R bind:bind /etc/bind
chmod -R 755 /etc/bind

# Allow the bind service through the firewall
ufw allow bind9

# Create the forward.mydomain.com file
cat > /etc/bind/zones/forward.mydomain.com <<- "EOF"
$TTL 86400
@       IN      SOA     nameserver.mydomain.com.        mydomain.com. (
                        2       ; Serial
                        604800  ; Refresh
                        86400   ; Retry
                        2419200 ; Expire
                        604800  ; Negative Cache TTL
)
; NAMESERVER DEFINITIONS
@       IN      NS      nameserver.mydomain.com.
; A RECORD DEFINITIONS
nameserver      IN      A       10.1.1.80
EOF

# Create the reverse.mydomain.com file
cat > /etc/bind/zones/reverse.mydomain.com <<- "EOF"
$TTL 86400
@       IN      SOA     nameserver.mydomain.com.        mydomain.com. (
                        2       ; Serial
                        604800  ; Refresh
                        86400   ; Retry
                        2419200 ; Expire
                        604800  ; Negative Cache TTL
)
; NAMESERVER DEFINITIONS
@       IN      NS      nameserver.mydomain.com.
; POINTER RECORDS
80      IN      PTR     nameserver.mydomain.com.
EOF

# Restart the bind service in order for the changes to take effect
systemctl restart bind9

# Enable the bind service to survive reboots
systemctl enable bind9

# Verify the syntax of the named.conf file
named-checkconf -z /etc/bind/named.conf

# Validate the zones' syntax
named-checkzone mydomain.com /etc/bind/zones/forward.mydomain.com
named-checkzone 1.1.10.in-addr.arpa /etc/bind/zones/reverse.mydomain.com

# Verify that the DNS server is listening on port 53
netstat -tulpen | grep 53

exit 0
