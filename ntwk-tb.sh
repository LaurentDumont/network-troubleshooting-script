#!/bin/bash

INF=enp7s0
HOSTNAME=`cat /etc/hostname`
IP_ADDRESS=`ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}'`
DNS_SERVERS=`grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/resolv.conf | head -1`

#CDP
#sudo tcpdump -nn -v -i enp6s0 -s 1500 -c 1 'ether[20:2] == 0x2000' > cdp_output

#Switch HOSTNAME
#cat cdp | grep -i "Device-ID" | cut -d ' ' -f7

#PORT ID
#cat cdp_output | grep -i Port-ID | cut -d ' ' -f7

#Switch model
#cat cdp | grep -i Platform | cut -d ' ' -f8

#IOS_VERSION_PART_1
#cat cdp | grep -i "Cisco IOS Software," | cut -d ' ' -f8

#IOS_VERSION_PART_2
#cat cdp | grep -i "Cisco IOS Software," | cut -d ' ' -f10

while true; do
    if ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' &> /dev/null ; then
        echo "Network Connection detected - Performing Network tests"

        DHCP_LEASE_TIME=`tail -n 500 /var/log/syslog | grep -i "lease time" | cut -d : -f5 | cut -d ' ' -f6 | sed '$!d'`
        DHCP_LEASE_TIME_MINUTES=`expr $DHCP_LEASE_TIME / 60`
        DHCP_SERVER_IP=`tail -n 500 /var/log/syslog | grep -i "server identifier" | cut -d : -f5  | cut -d ' ' -f6 | sed '$!d'`

        if ping -c 2 8.8.8.8 &> /dev/null && ping -c 2 8.8.4.4 &> /dev/null ; then
            curl -X POST -H 'Content-type: application/json' --data '{"text":"Network Connection detected on '"$HOSTNAME"'\nYour IP is '"$IP_ADDRESS"'\nYour DNS Server is '"$DNS_SERVERS"' \n Your DHCP lease time is '"$DHCP_LEASE_TIME_MINUTES"' minutes\n The DHCP Server is '"$DHCP_SERVER_IP"'"}' \
            INSERT_DISCORD_TOKEN &> /dev/null
        sleep 5
        else
            echo "Valid IP detected in interface but failed to ping 8.8.8.8 and 8.8.4.4"
        fi
    else
        echo "Could not determine if there was a valid IP on the interface"
    fi
done
