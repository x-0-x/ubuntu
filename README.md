
# Autoscript VPS (Ubuntu 20)
![OS](https://shields.io/badge/OS-Ubuntu%2020+-green?logo=ubuntu&style=for-the-badge) ![Virtualization](https://shields.io/badge/Virtualization-KVM-green?logo=tryhackme&style=for-the-badge) ![Architecture](https://shields.io/badge/Architecture-any-green?logo=moleculer&style=for-the-badge)

![Dropbear](https://shields.io/badge/Service-Dropbear-orange?logo=jamboard&style=for-the-badge) ![Stunnel](https://shields.io/badge/Service-Stunnel-orange?logo=keepassxc&style=for-the-badge) ![OpenVPN](https://shields.io/badge/Service-OpenVPN-orange?logo=openvpn&style=for-the-badge) ![Squid](https://shields.io/badge/Service-Squid-orange?logo=testinglibrary&style=for-the-badge) ![OHP](https://shields.io/badge/Service-OHP-orange?logo=openapiinitiative&style=for-the-badge) ![BadVPN UDPGw](https://shields.io/badge/Service-BadVPN%20UDPGw-orange?logo=ublockorigin&style=for-the-badge) ![Xray](https://shields.io/badge/Service-Xray-orange?logo=xstate&style=for-the-badge) ![WireGuard](https://shields.io/badge/Service-WireGuard-orange?logo=wireguard&style=for-the-badge) ![Nginx](https://shields.io/badge/Service-Nginx-orange?logo=onnx&style=for-the-badge)

Salam. Ini merupakan sebuah script yang memudahkan para seller VPN untuk install package-package yang diperlukan untuk berjualan VPN.

## Installed Services
Script ni akan install service VPN yang mainstream untuk kegunaan bypass Internet di Malaysia.

### VPN Services:
|No.|Service|Port|
|--|--|--|
|1|Dropbear|85|
|2|Stunnel|465|
|3|OpenVPN (UDP)|1194|
|4|OpenVPN (TCP)|1194|
|5|Squid Proxy|8080|
|6|Open-HTTP Puncher (Dropbear)|3128|
|7|Open-HTTP Puncher (OpenVPN)|3128|
|8|BadVPN UDPGw|7300|
|9|Xray|443|
|10|Xray WebSocket|81|
|11|WireGuard|51820|

### Other Services:
|No.|Service|Port|
|--|--|--|
|1|Nginx|80|
|2|Speedtest CLI|-|
|3|fail2ban|-|
|4|DDoS Deflate|-|
|5|rc-local|-|
|6|vnstat|-|

### Features:
- Timezone: Asia/Kuala_Lumpur (GMT +8)
- IPv6 disabled
- Reset Iptables
- Auto delete expired users
- Auto reboot daily
- Block BitTorrent via Iptables
- Google Drive backup and restore (SSH and Xray users only)

## Dependencies
- OS: Ubuntu 20+
- Virtualization: kvm
- Architecture: any (only x86_64 support OHP)
- isRoot

## Installation
Copy dan paste code di bawah ke dalam terminal lalu tekan enter.
```bash
wget -qO install.sh "https://raw.githubusercontent.com/iriszz-official/ubuntu/main/install.sh"; chmod +x install.sh; ./install.sh
```

## Akhir Kalam ...
Guna benda free ni sebaiknya, **JANGAN JUAL**. Jangan lupa feedback dekat saya di Telegram, [@iriszz](https://t.me/iriszz).

Join channel: [@VoidVPN](https://t.me/voidvpn)