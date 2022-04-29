#!/bin/bash

# Initialize variables
PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

checkRun() {
	if [[ "$(systemctl is-active $1)" == "active" ]]; then
		echo -e "${GREEN}Running${NC}"
	else
		echo -e "${RED}Not Running${NC}"
	fi
}

checkScreen() {
	if screen -ls | grep -qw $1; then
		echo -e "${GREEN}Running${NC}"
	else
		echo -e "${RED}Not Running${NC}"
	fi
}

checkService() {
	echo -e ""
	echo -e "==========[ Service Status ]=========="
	echo -e ""
	echo -e "SSH: $(checkRun ssh)"
	echo -e "Dropbear: $(checkRun dropbear)"
	echo -e "Stunnel: $(checkRun stunnel4)"
	echo -e "OpenVPN (UDP): $(checkRun openvpn@server-udp)"
	echo -e "OpenVPN (TCP): $(checkRun openvpn@server-tcp)"
	echo -e "Squid Proxy: $(checkRun squid)"
	echo -e "OHP Dropbear: $(checkScreen ohp-dropbear)"
	echo -e "OHP OpenVPN: $(checkScreen ohp-openvpn)"
	echo -e "BadVPN UDPGw: $(checkScreen badvpn)"
	echo -e "Nginx: $(checkRun nginx)"
	echo -e "Xray XTLS: $(checkRun xray@xtls)"
	echo -e "Xray WS: $(checkRun xray@ws)"
	echo -e "WireGuard: $(checkRun wg-quick@wg0)"
	echo -e "Fail2Ban: $(checkRun fail2ban)"
	echo -e "DDoS Deflate: $(checkRun ddos)"
	echo -e ""
}

checkStream() {
	bash <(curl -sSL https://raw.githubusercontent.com/Netflixxp/NF/main/nf.sh)
	echo -e ""
	rm -f check.log
}

if [[ $1 == "service" ]]; then
	checkService
elif [[ $1 == "stream" ]]; then
	checkStream
else
	echo -e "Invalid input!\n"
	echo -e "Usage: check-script service"
	echo -e "       check-script stream\n"
fi