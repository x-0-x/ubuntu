#!/bin/bash

function add-user() {
	clear
	echo -e ""
	echo -e "Add SSH & VPN User"
	echo -e "------------------"
	read -p "Username : " user
	if getent passwd $user > /dev/null 2>&1; then
		echo ""
		echo "User '$user' already exist."
		echo ""
		exit 0
	fi
	read -p "Password : " pass
	read -p "Duration (day) : " duration
	useradd -e $(date -d +${duration}days +%Y-%m-%d) -s /bin/false -M $user
	echo -e "$pass\n$pass\n"|passwd $user &> /dev/null
	echo -e "${user}\t${pass}\t$(date -d +${duration}days +%Y-%m-%d)" >> /voidvpn/ssh/ssh-clients.txt

	exp=$(date -d +${duration}days +"%d %b %Y")

	clear
	echo -e ""
	echo -e "SSH & VPN User Information"
	echo -e "--------------------------"
	echo -e "Username : $user "
	echo -e "Password : $pass"
	echo -e "Expired date : $exp"
	echo -e ""
}

function delete-user() {
	clear
	echo -e ""
	echo -e "Delete SSH & VPN User"
	echo -e "---------------------"
	read -p "Username : " user
	if getent passwd $user > /dev/null 2>&1; then
		userdel $user
		sed -i "/\b$user\b/d" /voidvpn/ssh/ssh-clients.txt
		echo -e ""
		echo -e "User '$user' deleted successfully."
		echo -e ""
	else
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
	fi
}

function extend-user() {
	clear
	echo -e ""
	echo -e "Extend SSH & VPN User"
	echo -e "---------------------"
	read -p "Username : " user
	if ! getent passwd $user > /dev/null 2>&1; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " extend

	exp_old=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)

	chage -E $(date -d +${duration}days +%Y-%m-%d) $user
	exp_new=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	clear
	echo -e ""
	echo -e "SSH & VPN User Information"
	echo -e "--------------------------"
	echo -e "Username : $user "
	echo -e "Expired date : $exp"
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	n=0
	while read expired; do
		account=$(echo $expired | cut -d: -f1)
		id=$(echo $expired | grep -v nobody | cut -d: -f3)
		exp=$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')

		if [[ $id -ge 1000 ]] && [[ $exp != "never" ]]; then
			exp_date=$(date -d "${exp}" +"%d %b %Y")
			printf "%-17s %2s\n" "$account" "$exp_date"
			n=$((n+1))
		fi
	done < /etc/passwd
	echo -e "-------------------------------"
	echo -e "Total accounts : $n"
	echo -e "==============================="
	echo -e ""
}

function user-monitor() {
	data=($(ps aux | grep -i dropbear | awk '{print $2}'))
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "    Dropbear Login Monitor"
	echo -e "-------------------------------"
	n=0
	for pid in "${data[@]}"; do
		num=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | wc -l)
		user=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $10}' | tr -d "'")
		ip=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $12}')
		if [ $num -eq 1 ]; then
			echo -e "$pid - $user - $ip"
			n=$((n+1))
		fi
	done
	echo -e "-------------------------------"
	echo -e "Total logins: $n"
	echo -e "==============================="
	echo -e ""
	echo -e "==============================="
	echo -e "  OpenVPN (TCP) Login Monitor"
	echo -e "-------------------------------"
	a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/server-tcp-status.log | awk -F":" '{print $1}')
	b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/server-tcp-status.log | awk -F":" '{print $1}') - 1)
	c=$(expr ${b} - ${a})
	cat /var/log/openvpn/server-tcp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g' > /tmp/openvpn-tcp-login.txt
	n=0
	while read login; do
		user=$(echo $login | awk '{print $1}')
		ip=$(echo $login | awk '{print $2}')
		echo -e "$user - $ip"
		n=$((n+1))
	done < /tmp/openvpn-tcp-login.txt
	echo -e "-------------------------------"
	echo -e "Total logins: $n"
	echo -e "==============================="
	echo -e ""
	echo -e "==============================="
	echo -e "  OpenVPN (UDP) Login Monitor"
	echo -e "-------------------------------"
	a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/server-udp-status.log | awk -F":" '{print $1}')
	b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/server-udp-status.log | awk -F":" '{print $1}') - 1)
	c=$(expr ${b} - ${a})
	cat /var/log/openvpn/server-udp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g' > /tmp/openvpn-udp-login.txt
	n=0
	while read login; do
		user=$(echo $login | awk '{print $1}')
		ip=$(echo $login | awk '{print $2}')
		echo -e "$user - $ip"
		n=$((n+1))
	done < /tmp/openvpn-udp-login.txt
	echo -e "-------------------------------"
	echo -e "Total logins: $n"
	echo -e "==============================="
	echo -e ""
}

function show-information() {
	clear
	echo -e ""
	echo -e "SSH Information"
	echo -e "---------------"
	read -p "User : " user
	if getent passwd $user > /dev/null 2>&1; then
		pass=$(cat /voidvpn/ssh/ssh-clients.txt | grep -w "$user" | awk '{print $2}')
		exp=$(cat /voidvpn/ssh/ssh-clients.txt | grep -w "$user" | awk '{print $3}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		ip=$(wget -qO- ipv4.icanhazip.com)
		echo -e "Password : $pass"
		echo -e "Expired : $exp_date"
		echo -e ""
		echo -e "Host Information"
		echo -e "----------------"
		echo -e "Host : $ip"
		echo -e "Dropbear : 85"
		echo -e "Stunnel : 465"
		echo -e "Squid Proxy : 8080"
		echo -e "OHP Dropbear : 3128"
		echo -e "OHP OpenVPN : 8000"
		echo -e "UDPGw : 7300"
		echo -e ""
		echo -e "OpenVPN Configuration"
		echo -e "---------------------"
		echo -e "OpenVPN TCP : 'cat /voidvpn/openvpn/client-tcp.ovpn'"
		echo -e "OpenVPN UDP : 'cat /voidvpn/openvpn/client-udp.ovpn'"
		echo -e ""
	else
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
	fi
}

function ovpn-config() {
	clear
	echo -e ""
	echo -e "OpenVPN Config"
	echo -e "--------------"
	echo -e "  [1] Config TCP"
	echo -e "  [2] Config UDP"
	echo -e "  [3] Exit"
	echo -e ""
	until [[ ${option} =~ ^[1-3]$ ]]; do
		read -rp "Select an option [1-3]: " option
	done

	case "${option}" in
	1)
		clear
		echo -e "OpenVPN Config - TCP"
		echo -e "--------------------"
		cat /voidvpn/openvpn/client-tcp.ovpn
		echo -e ""
		exit
		;;
	2)
		clear
		echo -e "OpenVPN Config - UDP"
		echo -e "--------------------"
		cat /voidvpn/openvpn/client-udp.ovpn
		echo -e ""
		exit
		;;
	3)
		clear
		exit 0
		;;
	esac
}

clear
echo -e ""
echo -e "==========[ SSH & VPN Menu ]=========="
echo -e ""
echo -e "  [1] Add user"
echo -e "  [2] Delete user"
echo -e "  [3] Extend user"
echo -e "  [4] User list"
echo -e "  [5] User monitor"
echo -e "  [6] Show SSH information"
echo -e "  [7] OVPN config"
echo -e ""
echo -e "  [x] Exit"
echo -e ""
until [[ ${option} -ge 1 ]] && [[ ${option} -le 7 ]] || [[ ${option} == 'x' ]]; do
	read -rp "Select an option [1-7 or x]: " option
done

case "${option}" in
	1)
		add-user
		exit
		;;
	2)
		delete-user
		exit
		;;
	3)
		extend-user
		exit
		;;
	4)
		user-list
		exit
		;;
	5)
		user-monitor
		exit
		;;
	6)
		show-information
		exit
		;;
	7)
		ovpn-config
		exit
		;;
	x)
		clear
		exit 0
		;;
esac