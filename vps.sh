#!/bin/bash
# ubuntu >= 18.04

v2rayPluginVersion=1.3.0
portDev=eth0

apt update
#echo "install lrzsz..."
#apt install -y lrzsz
echo "install vim..."
apt install -y vim

echo "open bbr..."
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
echo "open tcp fastopen..."
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
echo "open ip_forward..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "sysctl apply"
sysctl -p

echo "change ssh port to 22392"
sed -i "s/.*\\Port\\b.*/Port 22392/g" /etc/ssh/sshd_config
echo "restart ssh"
/etc/init.d/ssh restart

echo "install shadowsocks-libev..."
apt update
apt install -y shadowsocks-libev
echo "install v2ray-plugin..."
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v$v2rayPluginVersion/v2ray-plugin-linux-amd64-v$v2rayPluginVersion.tar.gz
tar zxf v2ray-plugin-linux-amd64-v$v2rayPluginVersion.tar.gz
mv v2ray-plugin_linux_amd64 /usr/bin/v2ray-plugin
echo '{
    "server":"0.0.0.0",
    "server_port":32682,
    "password":"123456@B",
    "nameserver":"8.8.8.8",
    "timeout":60,
    "method":"aes-256-gcm",
    "mode":"tcp_and_udp",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server"
}' > /etc/shadowsocks-libev/config.json
echo "restart shadowsocks-libev..."
systemctl restart shadowsocks-libev

ubuntuCode=`lsb_release -c -s`
echo "install nginx..."
echo 'deb http://nginx.org/packages/ubuntu/ '$ubuntuCode' nginx
deb-src http://nginx.org/packages/ubuntu/ '$ubuntuCode' nginx' > /etc/apt/sources.list.d/nginx.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
apt update
apt install -y nginx
echo "start nginx..."
service nginx start

echo "install wireguard..."
add-apt-repository ppa:wireguard/wireguard
apt update
apt install wireguard
cd /etc/wireguard/
wg genkey | tee server_privatekey | wg pubkey > server_publickey
pKey=`cat server_privatekey`
echo '[Interface]
PrivateKey = '$pKey'
Address = 192.168.120.1/24
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o '$portDev' -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o '$portDev' -j MASQUERADE
ListenPort = 50814
DNS = 8.8.8.8
MTU = 1420

[Peer]
PublicKey = 
AllowedIPs = 192.168.120.2/32' > wg0.conf
echo "up wg0..."
wg-quick up wg0
echo "set autostart..."
systemctl enable wg-quick@wg0
