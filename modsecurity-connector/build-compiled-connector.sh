#!/bin/bash

c='\e[32m' # Coloured echo (Green)
r='tput sgr0' #Reset colour after echo

if [[ $EUID -ne 0 ]]; then
   	echo -e "${c}Must be run as root, add \"sudo\" before script"; $r
   	exit 1
fi

echo -e "${c}Install default nginx version"; $r
apt-get update -y
apt-get install -y nginx

echo -e "${c}Installing Prerequisites"; $r
apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev


# ModSecurity Installation
echo -e "${c}Installing and setting up ModSecurity"; $r
cd
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install
cd ..
rm -rf ModSecurity

# ModSecurity NGINX Conector Module Installation
echo -e "${c}Downloading nginx connector for ModSecurity Module"; $r
cd
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
# Filter nginx version number only
nginxvnumber=$(nginx -v 2>&1 | grep -o '[0-9.]*')
echo -e "${c} Current version of nginx is: " $nginxvnumber; $r
wget http://nginx.org/download/nginx-"$nginxvnumber".tar.gz
tar zxvf nginx-"$nginxvnumber".tar.gz
rm -rf nginx-"$nginxvnumber".tar.gz
cd nginx-"$nginxvnumber"
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules

echo -e "${c}Copy library to folder"; $r
nginx_version=$(nginx -v 2>&1 | grep -Po '\d+\.\d+')
ubuntu_release=$(lsb_release -a 2>&1 | grep 'Release:.*' | sed 's/Release://' | awk '{$1=$1};1')
mkdir ${ubuntu_release}_${nginx_version}
cp objs/ngx_http_modsecurity_module.so ${ubuntu_release}_${nginx_version}
