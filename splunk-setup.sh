#!/bin/bash

cred="$1"
address="$2"
hostname="$3"
if [ "${#cred}" == '0' ]; then
    echo "[EXIT] - credential not provided, please run: bash $0 <acc:pass> <ip:port> <hostname>"
    exit;
fi

if [ "${#address}" == '0' ]; then
    echo "[EXIT] - address not provided, please run: bash $0 <acc:pass> <ip:port> <hostname>"
    exit;
fi

if [ "${#hostname}" == '0' ]; then
    echo "[EXIT] - hostname not provided, please run: bash $0 <acc:pass> <ip:port> <hostname>"
    exit;
fi

echo "Cred: $cred"
echo "Addr: $address"
echo "Hostname: $hostname"

echo "[+] - Installing and starting the Splunk universal forwarder"
dpkg -i ./resources/splunkforwarder-9.0.1-82c987350fde-linux-2.6-amd64.deb &&
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --seed-passwd Abc123456 &&

echo "[+] - Configuring the Splunk universal forwarder"
/opt/splunkforwarder/bin/splunk enable boot-start -auth $cred &&
echo "[INFO] - Add forward-server"
/opt/splunkforwarder/bin/splunk add forward-server $address -auth $cred &&
echo "[INFO] - Add monitor directory"
/opt/splunkforwarder/bin/splunk add monitor /var/log/modsec &&

echo "[+] - Configuring..."
FILE="/opt/splunkforwarder/etc/system/local/inputs.conf"
echo "[default]" >> $FILE
echo "host=$hostname" >> $FILE
echo "[monitor:///var/log/modsec/]" >> $FILE
echo "disabled=false" >> $FILE
echo "index=proxy" >> $FILE
echo "sourcetype=proxy" >> $FILE
echo "initCrcLength=654" >> $FILE

echo "[+] - Restarting spunk, gonna take a while!"
/opt/splunkforwarder/bin/splunk restart &&

echo "[+] - Show configs"
/opt/splunkforwarder/bin/splunk show default-hostname -auth $cred &&
/opt/splunkforwarder/bin/splunk list forward-server -auth $cred &&
cat /opt/splunkforwarder/etc/system/local/outputs.conf
