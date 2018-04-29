#!/bin/bash

INF=enp7s0
HOSTNAME=`cat /etc/hostname`
IP_ADDRESS=`ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}'`
DNS_SERVERS=`grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/resolv.conf | head -1`

#Get DHCP Lease time
#sudo tail -n 500 /var/log/syslog | grep -i "lease time" | cut -d : -f5 | cut -d ' ' -f6 | sed '$!d'

while true; do
    if ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' &> /dev/null ; then
        echo "Network Connection detected - Performing Network tests"
        if ping -c 2 8.8.8.8 &> /dev/null && ping -c 2 8.8.4.4 &> /dev/null ; then
            curl -X POST -H 'Content-type: application/json' --data '{"text":"Network Connection detected on '"$HOSTNAME"'\nYour IP is '"$IP_ADDRESS"'\nYour DNS Server is '"$DNS_SERVERS"' "}' DISCORD_WEBHOOK_URL_HERE &> /dev/null
        sleep 5
        else
            echo "Valid IP detected in interface but failed to ping 8.8.8.8 and 8.8.4.4"
        fi
    else
        echo "Could not determine if there was a valid IP on the interface"
    fi
done

