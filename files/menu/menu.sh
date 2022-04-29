#!/bin/bash

repoDir='https://raw.githubusercontent.com/iriszz-official/ubuntu/main/'

updateScript() {
	echo -e ""
	echo -e "Updating script ..."
	sleep 1
	rm -f /usr/bin/{menu,ssh-vpn-script,xray-script,wireguard-script,check-script,backup-script}
	rm -f /voidvpn/cron.daily
	wget -O /usr/bin/menu "${repoDir}files/menu/menu.sh" > /dev/null 2>&1
	wget -O /usr/bin/ssh-vpn-script "${repoDir}files/menu/ssh-vpn-script.sh" > /dev/null 2>&1
	wget -O /usr/bin/xray-script "${repoDir}files/menu/xray-script.sh" > /dev/null 2>&1
	wget -O /usr/bin/wireguard-script "${repoDir}files/menu/wireguard-script.sh" > /dev/null 2>&1
	wget -O /usr/bin/check-script "${repoDir}files/menu/check-script.sh" > /dev/null 2>&1
	wget -O /usr/bin/backup-script "${repoDir}files/menu/backup-script.sh" > /dev/null 2>&1
	wget -O /voidvpn/cron.daily "${repoDir}files/cron.daily" > /dev/null 2>&1
	chmod +x /usr/bin/{menu,ssh-vpn-script,xray-script,wireguard-script,check-script,backup-script}
	chmod +x /voidvpn/cron.daily
	echo -e "Script updated.\n"
}

clear
echo -e ""
echo -e "============[ Script Menu ]============"
echo -e ""
echo -e "VPN Services"
echo -e "------------"
echo -e "  [1] SSH & OVPN Menu"
echo -e "  [2] Xray Menu"
echo -e "  [3] WireGuard Menu"
echo -e ""
echo -e "Server Tools"
echo -e "------------"
echo -e "  [4] Server Speedtest"
echo -e "  [5] Server Benchmark"
echo -e ""
echo -e "Other"
echo -e "-----"
echo -e "  [6] Check Service Status"
echo -e "  [7] Check Streaming Service"
echo -e "  [8] Backup and Restore"
echo -e "  [9] Update Script"
echo -e ""
echo -e "  [x] Exit"
echo -e ""
until [[ ${option} -ge 1 ]] && [[ ${option} -le 9 ]] || [[ ${option} == 'x' ]]; do
	read -rp "Select an option [1-9 or x]: " option
done

case "${option}" in
	1)
		ssh-vpn-script
		exit
		;;
	2)
		xray-script
		exit
		;;
	3)
		wireguard-script
		exit
		;;
	4)
		clear
		speedtest
		echo -e ""
		exit
		;;
	5)
		clear
		echo -e ""
		wget -qO- "wget.racing/nench.sh" | bash
		exit
		;;
	6)
		clear
		check-script service
		exit
		;;
	7)
		clear
		check-script stream
		exit
		;;
	8)
		clear
		backup-script
		exit
		;;
	9)
		updateScript
		exit 0
		;;
	x)
		clear
		exit 0
		;;
esac