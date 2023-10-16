#!/bin/bash

c='\e[32m' # Coloured echo (Green)
r='tput sgr0' # Reset colour after echo
y='\e[33m' # yellow
re='\e[31m' # red

if [[ $EUID -ne 0 ]]; then
   	echo -e "${re}Must be run as root, add \"sudo\" before script"; $r
   	exit 1
else
  echo -e "${y}Root privileges ok"; $r
fi

echo -e "${c}Installing nginx 1.18.0"; $r
sudo apt update -y
sudo apt install -y nginx=1.18.*
echo -e "${c}Checking NGINX version"; $r
nginx -v

echo -e "${c}Installing ModSecurity module v3"; $r
# Download Source to get config
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/local/src/ModSecurity/
# Install libmodsecurity3 for linux, no need compiling
sudo apt -y install libmodsecurity3

echo -e "${c}Get nginx connector for ModSecurity Module"; $r
# compiled connector for nginx version 1.18.0 (compiled version have to match)
mkdir /etc/nginx/modules
cp ./modsecurity-connector/1.18.0/ngx_http_modsecurity_module.so  /etc/nginx/modules/ngx_http_modsecurity_module.so

echo -e "${c}Create /etc/nginx/nginx.conf backup file"; $r
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
echo -e "${c}Enable ModSecurity in nginx.conf"; $r
sed -i '1i\load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf
sed -i '/http {/a \    modsecurity on;\n    modsecurity_rules_file /etc/nginx/modsec/modsec-config.conf;' /etc/nginx/nginx.conf

echo -e "${c}Preparing configuration for nginx modsec"; $r
sudo mkdir /var/log/modsec/
sudo chmod 777 /var/log/modsec/
sudo mkdir /etc/nginx/modsec/
sudo cp /usr/local/src/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
sed -i 's/SecAuditLogParts ABIJDEFHZ/SecAuditLogParts ABCEFHJKZ/' /etc/nginx/modsec/modsecurity.conf
sed -i 's/SecAuditEngine RelevantOnly/SecAuditEngine On/' /etc/nginx/modsec/modsecurity.conf
sed -i 's/SecAuditLogType Serial/#SecAuditLogType Serial/' /etc/nginx/modsec/modsecurity.conf
sed -i 's#^SecAuditLog /var/log/modsec_audit.log#SecAuditLogFormat JSON\nSecAuditLogType Concurrent\nSecAuditLogStorageDir /var/log/modsec/\nSecAuditLogFileMode 0777\nSecAuditLogDirMode 0777#' /etc/nginx/modsec/modsecurity.conf

# Create modsec-config.conf File
echo "Include /etc/nginx/modsec/modsecurity.conf" > /etc/nginx/modsec/modsec-config.conf
sudo cp /usr/local/src/ModSecurity/unicode.mapping /etc/nginx/modsec/
rm -rf /usr/local/src/ModSecurity # done with source

echo -e "${c}Install OWASP Core Rule Set for ModSecurity 3"; $r
cd /etc/nginx/modsec
wget https://github.com/coreruleset/coreruleset/archive/refs/tags/nightly.tar.gz
tar -xvf nightly.tar.gz
sudo cp /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf.example /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf
echo "Include /etc/nginx/modsec/coreruleset-nightly/crs-setup.conf" >> /etc/nginx/modsec/modsec-config.conf
echo "Include /etc/nginx/modsec/coreruleset-nightly/rules/*.conf" >> /etc/nginx/modsec/modsec-config.conf
rm -rf nightly.tar.gz


echo -e "${c}Remove some OWASP rules because of parsing error due to Modsec version compatibility (libmodsecurity3.0.6-1)"; $r
# https://forum.directadmin.com/threads/owasp-modsecurity-core-rule-set-version-3-3-4.67101/
sudo rm /etc/nginx/modsec/coreruleset-nightly/rules/REQUEST-922-MULTIPART-ATTACK.conf

echo -e "${c}Test and restart!"; $r
nginx -t
service nginx restart

echo -e "${c}Test OWASP rules: curl 'http://localhost/?ggg=<script>alert(1)</script>'"; $r
xss_test=$(curl -s 'http://localhost/?ggg=<script>alert(1)</script>')
echo "$xss_test";
if [[ "403 Forbidden" == *$xss_tes* ]] && [ "${#xss_test}" != '0' ]; then
  echo -e "${y}[403 Forbidden]: Malicious requets blocked. Setup nginx ModSecurity successful!"; $r
  echo -e "${y}Check out audit log: /var/log/modsec/"; $r
else
  echo -e "${re}Not 403??, block failed, please check setup logs!"; $r
fi
