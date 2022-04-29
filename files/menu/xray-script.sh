#!/bin/bash

function add-user() {
	clear
	echo -e ""
	echo -e "Add Xray User"
	echo -e "-------------"
	read -p "Username : " user
	if grep -qw "$user" /voidvpn/xray/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' already exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " duration

	uuid=$(uuidgen)
	while grep -qw "$uuid" /voidvpn/xray/xray-clients.txt; do
		uuid=$(uuidgen)
	done
	exp=$(date -d +${duration}days +%Y-%m-%d)
	expired=$(date -d "${exp}" +"%d %b %Y")
	domain=$(cat /usr/local/etc/xray/domain)
	email=${user}@${domain}
	echo -e "${user}\t${uuid}\t${exp}" >> /voidvpn/xray/xray-clients.txt

	cat /usr/local/etc/xray/xtls.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","flow": "xtls-rprx-direct","email": "'${email}'"}]' > /usr/local/etc/xray/xtls_tmp.json
	mv -f /usr/local/etc/xray/xtls_tmp.json /usr/local/etc/xray/xtls.json
	cat /usr/local/etc/xray/ws.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/ws_tmp.json
	mv -f /usr/local/etc/xray/ws_tmp.json /usr/local/etc/xray/ws.json
	systemctl daemon-reload
	systemctl restart xray@xtls
	systemctl restart xray@ws

	clear
	echo -e ""
	echo -e "Xray User Information"
	echo -e "---------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $expired"
	echo -e ""
}

function delete-user() {
	clear
	echo -e ""
	echo -e "Delete Xray User"
	echo -e "----------------"
	read -p "Username : " user
	if ! grep -qw "$user" /voidvpn/xray/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid="$(cat /voidvpn/xray/xray-clients.txt | grep -w "$user" | awk '{print $2}')"

	cat /usr/local/etc/xray/xtls.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/xray/xtls_tmp.json
	mv -f /usr/local/etc/xray/xtls_tmp.json /usr/local/etc/xray/xtls.json
	cat /usr/local/etc/xray/ws.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/xray/ws_tmp.json
	mv -f /usr/local/etc/xray/ws_tmp.json /usr/local/etc/xray/ws.json
	sed -i "/\b$user\b/d" /voidvpn/xray/xray-clients.txt
	systemctl daemon-reload
	systemctl restart xray@xtls
	systemctl restart xray@ws
	echo -e ""
	echo -e "User '$user' deleted successfully."
	echo -e ""
}

function extend-user() {
	clear
	echo -e ""
	echo -e "Extend Xray User"
	echo -e "----------------"
	read -p "Username : " user
	if ! grep -qw "$user" /voidvpn/xray/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " extend

	uuid=$(cat /voidvpn/xray/xray-clients.txt | grep -w $user | awk '{print $2}')
	exp_old=$(cat /voidvpn/xray/xray-clients.txt | grep -w $user | awk '{print $3}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)
	exp_new=$(date -d +${duration}days +%Y-%m-%d)
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	sed -i "/\b$user\b/d" /voidvpn/xray/xray-clients.txt
	echo -e "$user\t$uuid\t$exp_new" >> /voidvpn/xray/xray-clients.txt

	clear
	echo -e ""
	echo -e "Xray User Information"
	echo -e "---------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $exp"
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired; do
		user=$(echo $expired | awk '{print $1}')
		exp=$(echo $expired | awk '{print $3}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		printf "%-17s %2s\n" "$user" "$exp_date"
	done < /voidvpn/xray/xray-clients.txt
	total=$(wc -l /voidvpn/xray/xray-clients.txt | awk '{print $1}')
	echo -e "-------------------------------"
	echo -e "Total accounts: $total"
	echo -e "==============================="
	echo -e ""
}

function user-monitor() {
	data=($(cat /voidvpn/xray/xray-clients.txt | awk '{print $1}'))
	data2=($(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | grep -w 443 | awk '{print $5}' | cut -d: -f1 | sort | uniq))
	domain=$(cat /usr/local/etc/xray/domain)
	clear
	echo -e ""
	echo -e "==========================="
	echo -e "  Xray-XTLS Login Monitor"
	echo -e "---------------------------"
	n=0
	for user in "${data[@]}"; do
		touch /tmp/ipxray.txt
		for ip in "${data2[@]}"; do
			total=$(cat /var/log/xray/access-xtls.log | grep -w ${user}@${domain} | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq)
			if [[ "$total" == "$ip" ]]; then
				echo -e "$total" >> /tmp/ipxray.txt
				n=$((n+1))
			fi
		done
		total=$(cat /tmp/ipxray.txt)
		if [[ -n "$total" ]]; then
			total2=$(cat /tmp/ipxray.txt | nl)
			echo -e "$user :"
			echo -e "$total2"
		fi
		rm -f /tmp/ipxray.txt
	done
	echo -e "---------------------------"
	echo -e "Total logins: $n"
	echo -e "==========================="
	echo -e ""
	echo -e "==========================="
	echo -e "   Xray-WS Login Monitor"
	echo -e "---------------------------"
	n=0
	data3=($(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | grep -w 81 | awk '{print $5}' | cut -d: -f1 | sort | uniq))
	for user in "${data[@]}"; do
		touch /tmp/ipxray.txt
		for ip in "${data3[@]}"; do
			total=$(cat /var/log/xray/access-ws.log | grep -w ${user}@${domain} | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq)
			if [[ "$total" == "$ip" ]]; then
				echo -e "$total" >> /tmp/ipxray.txt
				n=$((n+1))
			fi
		done
		total=$(cat /tmp/ipxray.txt)
		if [[ -n "$total" ]]; then
			total2=$(cat /tmp/ipxray.txt | nl)
			echo -e "$user :"
			echo -e "$total2"
		fi
		rm -f /tmp/ipxray.txt
	done
	echo -e "---------------------------"
	echo -e "Total logins: $n"
	echo -e "==========================="
	echo -e ""
}

function show-config() {
	echo -e ""
	echo -e "Xray Config"
	echo -e "-----------"
	read -p "User : " user
	if ! grep -qw "$user" /voidvpn/xray/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid=$(cat /voidvpn/xray/xray-clients.txt | grep -w "$user" | awk '{print $2}')
	domain=$(cat /usr/local/etc/xray/domain)
	exp=$(cat /voidvpn/xray/xray-clients.txt | grep -w "$user" | awk '{print $3}')
	exp_date=$(date -d"${exp}" "+%d %b %Y")

	echo -e "Expired : $exp_date"
	echo -e ""
	echo -e "VLESS + TLS / XTLS"
	echo -e "------------------"
	echo -e "Adress : $domain"
	echo -e "Port : 443"
	echo -e "ID : $uuid"
	echo -e "Flow : xtls-rprx-direct"
	echo -e "Encryption : none"
	echo -e "Network : tcp"
	echo -e "Header Type : none"
	echo -e "TLS : tls / xtls"
	echo -e ""
	echo -e "Link : vless://$uuid@$domain:443?security=xtls&encryption=none&flow=xtls-rprx-direct&sni=${domain}#XRAY_XTLS-$user"
	echo -e ""
	echo -e "QR Code"
	echo -e "-------"
	qrencode -t ansiutf8 -l L "vless://$uuid@$domain:443?security=xtls&encryption=none&flow=xtls-rprx-direct&sni=${domain}#XRAY_XTLS-$user"
	echo -e ""
	echo -e "VLESS + WS"
	echo -e "----------"
	echo -e "Adress : $domain"
	echo -e "Port : 81"
	echo -e "ID : $uuid"
	echo -e "Encryption : none"
	echo -e "Network : ws"
	echo -e "Path : /xray"
	echo -e ""
	echo -e "Link : vless://$uuid@$domain:81?path=%2Fxray&security=none&encryption=none&host=$domain&type=ws#XRAY_WS-$user"
	echo -e ""
	echo -e "QR Code"
	echo -e "-------"
	qrencode -t ansiutf8 -l L "vless://$uuid@$domain:81?path=%2Fxray&security=none&encryption=none&host=$domain&type=ws#XRAY_WS-$user"
	echo -e ""
}

clear
echo -e ""
echo -e "=============[ Xray Menu ]============="
echo -e ""
echo -e "  [1] Add Xray user"
echo -e "  [2] Delete Xray user"
echo -e "  [3] Extend Xray user"
echo -e "  [4] Xray user list"
echo -e "  [5] Xray user monitor"
echo -e "  [6] Show Xray configuration"
echo -e ""
echo -e "  [x] Exit"
echo -e ""
until [[ ${option} -ge 1 ]] && [[ ${option} -le 6 ]] || [[ ${option} == 'x' ]]; do
	read -rp "Select an option [1-6 or x]: " option
done
case "${option}" in
1)
	add-user
	;;
2)
	delete-user
	;;
3)
	extend-user
	;;
4)
	user-list
	;;
5)
	user-monitor
	;;
6)
	clear
	show-config
	;;
x)
	clear
	exit 0
	;;
esac