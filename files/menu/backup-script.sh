#!/bin/bash

PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
today=$(date +%Y-%m-%d)

startBackup() {
	echo -e ""
	echo -e "${PURPLE}[+] Starting backup ...${NC}"
	sleep 1
	if gdrive list | grep -qw "vpn backup"; then
		folderID=$(gdrive list | grep -w "vpn backup" | awk '{print $1}')
		gdrive delete -r $folderID > /dev/null 2>&1
		gdrive mkdir "vpn backup" --description "VPN account backup folder. Script by Void VPN." > /dev/null 2>&1
		folderID=$(gdrive list | grep -w "vpn backup" | awk '{print $1}')
	else
		gdrive mkdir "vpn backup" --description "VPN account backup folder. Script by Void VPN." > /dev/null 2>&1
		folderID=$(gdrive list | grep -w "vpn backup" | awk '{print $1}')
	fi
	rm -rf /backup-vpn
	mkdir /backup-vpn
	cp /voidvpn/xray/xray-clients.txt /backup-vpn/
	cp /voidvpn/ssh/ssh-clients.txt /backup-vpn/
	echo $(date) > /backup-vpn/.date
	echo $(cat /usr/local/etc/xray/domain) > /backup-vpn/.domain
	tar -zcf backup-vpn.tar.gz /backup-vpn/ > /dev/null 2>&1
	gdrive upload -p $folderID backup-vpn.tar.gz
	rm -rf backup-vpn.tar.gz /backup-vpn
	echo -e "${PURPLE}[+] Backup complete ...${NC}\n"
}

startRestore() {
	echo -e ""
	echo -e "${PURPLE}[+] Starting restore ...${NC}"
	sleep 1
	if ! gdrive list | grep -qw "backup-vpn.tar.gz"; then
		echo -e "${RED}Backup file not found!${NC}\n"
		exit 1
	fi

	fileID=$(gdrive list | grep -w "backup-vpn.tar.gz" | awk '{print $1}')
	gdrive download --path /tmp/ $fileID > /dev/null 2>&1
	tar -zxf /tmp/backup-vpn.tar.gz -C /tmp/ > /dev/null 2>&1

	cd /tmp/backup-vpn
	echo -e "Backup date: $(cat .date)"
	echo -e "Backup domain: $(cat .domain)"
	echo -e "${PURPLE}[+] Restoring ...${NC}"
	if ! [[ -s xray-clients.txt ]]; then
		echo -e "No Xray users to be restored."
	else
		echo -e "Xray Users:"
		sleep 1
		s=0
		f=0
		while read account; do
			user=$(echo $account | awk '{print $1}')
			uuid=$(echo $account | awk '{print $2}')
			exp=$(echo $account | awk '{print $3}')
			if grep -qw "$user" /voidvpn/xray/xray-clients.txt; then
				echo -e "  ${RED}User '${user}' already exist. Not creating.${NC}"
				f=$((f+1))
			else
				if grep -qw "$uuid" /voidvpn/xray/xray-clients.txt; then
					echo -e "  ${RED}UUID for user '${user}' (${uuid}) already exist. Not creating.${NC}"
					f=$((f+1))
				else
					domain=$(cat /usr/local/etc/xray/domain)
					email=${user}@${domain}
					echo -e "${user}\t${uuid}\t${exp}" >> /voidvpn/xray/xray-clients.txt
					cat /usr/local/etc/xray/xtls.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","flow": "xtls-rprx-direct","email": "'${email}'"}]' > /usr/local/etc/xray/xtls_tmp.json
					mv -f /usr/local/etc/xray/xtls_tmp.json /usr/local/etc/xray/xtls.json
					cat /usr/local/etc/xray/ws.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/ws_tmp.json
					mv -f /usr/local/etc/xray/ws_tmp.json /usr/local/etc/xray/ws.json
					echo -e "  ${GREEN}User '${user}' restored.${NC}"
					s=$((s+1))
				fi
			fi
		done < xray-clients.txt
		echo -e "Result Xray:"
		if [[ s -gt 0 ]]; then
			systemctl daemon-reload
			systemctl restart xray@xtls
			systemctl restart xray@ws
			echo -e "  Successfully restored '${GREEN}${s}${NC}' Xray user(s)."
		elif [[ f -gt 0 ]]; then
			echo -e "  Failed to restore '${RED}${f}${NC}' Xray user(s)."
		fi
	fi

	if ! [[ -s ssh-clients.txt ]]; then
		echo -e "No SSH users to be restored."
	else
		echo -e "SSH users:"
		sleep 1
		s=0
		f=0
		while read account; do
			user=$(echo $account | awk '{print $1}')
			pass=$(echo $account | awk '{print $2}')
			exp=$(echo $account | awk '{print $3}')
			if getent passwd $user > /dev/null 2>&1; then
				echo -e "  ${RED}User '${user}' already exist. Not creating.${NC}"
				f=$((f+1))
			elif [[ $exp < $today ]]; then
				echo -e "  ${RED}User '${user}' already expired. Not creating.${NC}"
				f=$((f+1))
			else
				remaining=$(( ($(date --date="$exp" +%s) - $(date --date="$today" +%s) )/(60*60*24) ))
				echo -e "${user}\t${pass}\t${exp}" >> /voidvpn/ssh/ssh-clients.txt
				useradd -e $(date -d +${remaining}days +%Y-%m-%d) -s /bin/false -M $user
				echo -e "$pass\n$pass\n"|passwd $user &> /dev/null
				echo -e "  ${GREEN}User '${user}' restored.${NC}"
				s=$((s+1))
			fi
		done < ssh-clients.txt
		echo -e "Result SSH:"
		if [[ s -gt 0 ]]; then
			echo -e "  Successfully restored '${GREEN}${s}${NC}' SSH user(s)."
		elif [[ f -gt 0 ]]; then
			echo -e "  Failed to restore '${RED}${f}${NC}' SSH user(s)."
		fi
	fi

	cd
	rm -rf /tmp/{backup-vpn,backup-vpn.tar.gz}
	echo -e "${PURPLE}[+] Restore complete.${NC}"
	echo -e ""
}

main() {
	clear
	echo -e ""
	echo -e "========[ Backup and Restore ]========"
	echo -e ""
	echo -e "Google Drive account details"
	echo -e "----------------------------"
	gdrive about
	echo -e ""
	echo -e "  [1] Backup"
	echo -e "  [2] Restore"
	echo -e ""
	echo -e "  [x] Exit"
	echo -e ""
	until [[ ${option} -ge 1 ]] && [[ ${option} -le 2 ]] || [[ ${option} == 'x' ]]; do
		read -rp "Select an option [1-2 or x]: " option
	done
	case "${option}" in
	1)
		clear
		startBackup
		;;
	2)
		clear
		startRestore
		;;
	x)
		clear
		exit 0
		;;
	esac
}

if [[ $1 == "backup" ]]; then
	startBackup
elif [[ $1 == "restore" ]]; then
	startRestore
else
	main
fi