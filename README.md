# Simple ModSecurity NGINX Setup + OWASP CRS Setup

Simple bash script to automatically install and setup ModSecurity Nginx and add OWASP Core Rule Set (CRS)

This script support default nginx version corresponding to lately Ubuntu LTS version with already compiled `libmodsecurity3` and `ModSecurity Nginx Connector` so it doesn't require to compile both modules from source, which save alot of time and resources

**Ideas**: https://github.com/shubhampathak/ModSecurity-NGINX-setup
## Compatibility
**Tested again**: `Ubuntu 22.04.2 LTS/nginx 1.18.0`, `Ubuntu 20.04.6 LTS/nginx 1.18.0`

## setup-modsec-nginx.sh
This script will:
1. Install default `nginx`, `libmodsecurity3` via `apt install`
2. Setup nginx modsecurity configuration with `ModSecurity Nginx Connector` from compiled binaries above, source: https://github.com/SpiderLabs/ModSecurity-nginx.git
3. Install OWASP Core Rule Set for ModSecurity 3, source: https://github.com/coreruleset/coreruleset
4. Enable & Test


## Usage
Just run:
```bash
sudo bash setup-modsec-nginx.sh
```

Example setup successful:

![success.png](images/success.png)
