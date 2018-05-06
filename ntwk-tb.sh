#!/bin/bash

#Script variables. Change $INF to appropriate interface if needed.
INF=enp6s0
HOSTNAME=`cat /etc/hostname`
IP_ADDRESS=`ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}'`
DNS_SERVERS=`grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/resolv.conf | head -1`

#Source discord/slack token
source ./token_file
echo $WEBHOOK_TOKEN

while true; do
    if ip a | sed -rn '/: '"$INF"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' &> /dev/null ; then
        echo "Network Connection detected - Performing Network tests"

        DHCP_LEASE_TIME=`tail -n 500 /var/log/syslog | grep -i "lease time" | cut -d : -f5 | cut -d ' ' -f6 | sed '$!d'`
        DHCP_LEASE_TIME_MINUTES=`expr $DHCP_LEASE_TIME / 60`
        DHCP_SERVER_IP=`tail -n 500 /var/log/syslog | grep -i "server identifier" | cut -d : -f5  | cut -d ' ' -f6 | sed '$!d'`

        if ping -c 2 8.8.8.8 &> /dev/null && ping -c 2 8.8.4.4 &> /dev/null ; then
            tcpdump -nn -v -i $INF -s 1500 -c 1 'ether[20:2] == 0x2000' > /tmp/cdp_output
            SWITCH_HOSTNAME=`grep -i "Device-ID" /tmp/cdp_output | cut -d ' ' -f7`
            SWITCHPORT_ID=`grep -i Port-ID /tmp/cdp_output | cut -d ' ' -f7`
            SWITCH_MODEL=`grep -i Platform /tmp/cdp_output | cut -d ' ' -f8`
            IOS_VERSION_PART_1=`grep -i "Cisco IOS Software," /tmp/cdp_output | cut -d ' ' -f8`
            IOS_VERSION_PART_2=`grep -i "Cisco IOS Software," /tmp/cdp_output | cut -d ' ' -f10`
            curl -X POST -H 'Content-type: application/json' --data '{"text":"Network Connection detected on '"$HOSTNAME"'\nYour IP is '"$IP_ADDRESS"'\nYour DNS Server is '"$DNS_SERVERS"' \nYour DHCP lease time is '"$DHCP_LEASE_TIME_MINUTES"' minutes\nThe DHCP Server is '"$DHCP_SERVER_IP"'\nYour switch is '"$SWITCH_HOSTNAME"'\nThe switchport is '"$SWITCHPORT_ID"'\nThe switch model is '"$SWITCH_MODEL"'\nThe switch IOS Version is '"$IOS_VERSION_PART_1 -"''"$IOS_VERSION_PART_2"'"}' \
            $WEBHOOK_TOKEN
        sleep 5
        else
            echo "Valid IP detected in interface but failed to ping 8.8.8.8 and 8.8.4.4"
        fi
    else
        echo "Could not determine if there was a valid IP on the interface"
    fi
done
