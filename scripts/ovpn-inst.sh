#!/bin/bash
USR=$(id -u)
GRP=$(id -g)
RELEASE=$(grep -oE "18.04|20.04" /etc/os-release | head -1)
SRVNAME=$(cat /etc/hostname)
echo "Вводите имя клиента:"
read CLIENT

if [ $RELEASE="18.04" ]; then
  echo "Выпуск ОС: $RELEASE"
  sudo apt update
  sudo apt install openvpn tree
  wget -P /tmp/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
  tar xf /tmp/EasyRSA-3.0.4.tgz -C /tmp/ && mv /tmp/EasyRSA-3.0.4 /tmp/easyrsa
  # cp -R /usr/share/easy-rsa /tmp/easyrsa
  /tmp/easyrsa/easyrsa init-pki 
  /tmp/easyrsa/easyrsa build-ca 
  echo "Идет генерация сертификатов ..."
  /tmp/easyrsa/easyrsa gen-dh   &>/dev/null 
  /tmp/easyrsa/easyrsa gen-crl  &>/dev/null 
  openvpn --genkey --secret /home/$USER/pki/ta.key
  echo -e "\033[01;32m[ S ]\033[00;37m :: Сертификаты готовы !\r\n"
  /tmp/easyrsa/easyrsa build-server-full $SRVNAME nopass
  echo $SRVNAME
  sudo mkdir /etc/openvpn/server/$SRVNAME
  mkdir /tmp/vpncl
  /tmp/easyrsa/easyrsa build-client-full $CLIENT nopass
  sudo mv /home/$USER/pki/ /etc/openvpn/server/$SRVNAME
  sudo cp /etc/openvpn/server/$SRVNAME/pki/ca.crt /etc/openvpn/server/$SRVNAME/pki/ta.key\
         /tmp/vpncl/
  sudo mv /etc/openvpn/server/$SRVNAME/pki/issued/$CLIENT.crt /tmp/vpncl/\
         /etc/openvpn/server/$SRVNAME/pki/private/$CLIENT.key /tmp/vpncl/
  sudo chown -R $USR:$GRP /tmp/vpncl
  echo -e "\033[01;32m[ S ]\033[00;37m :: Набор ключей и сертификатов готов !\r\n"
elif [ $RELEASE="20.04" ]; then
  echo "Выпуск ОС: $RELEASE"
  sudo apt update
  sudo apt install openvpn easy-rsa tree
  mkdir /tmp/easyrsa
  mkdir /tmp/vpncl
  cp -R /usr/share/easy-rsa/ /tmp/easyrsa/
  /tmp/easyrsa/easyrsa init-pki 
  /tmp/easyrsa/easyrsa build-ca 
  echo "Идет генерация сертификатов ..."
  /tmp/easyrsa/easyrsa gen-dh   &>/dev/null 
  /tmp/easyrsa/easyrsa gen-crl  &>/dev/null 
  openvpn --genkey --secret /home/$USER/pki/ta.key
  echo -e "\033[01;32m[ S ]\033[00;37m :: Сертификаты готовы !\r\n"
  /tmp/easyrsa/easyrsa build-server-full $SRVNAME nopass
  echo $SRVNAME
  sudo mkdir /etc/openvpn/server/$SRVNAME
  sudo mkdir /etc/openvpn/client/$CLIENT
  /tmp/easyrsa/easyrsa build-client-full $SRVNAME nopass
  sudo cp -R /home/$USER/pki/ /etc/openvpn/server/$SRVNAME
  sudo mv /home/$USER/pki/ /etc/openvpn/server/$SRVNAME
  sudo cp /etc/openvpn/server/$SRVNAME/pki/ca.crt /etc/openvpn/server/$SRVNAME/pki/ta.key\
         /tmp/vpncl/
  sudo mv /etc/openvpn/server/$SRVNAME/pki/issued/$CLIENT.crt /tmp/vpncl/\
         /etc/server/client/$SRVNAME/pki/private/$CLIENT.key /tmp/vpncl/
  sudo chown -R $USR:$GRP /tmp/vpncl
  echo -e "\033[01;32m[ S ]\033[00;37m :: Набор ключей и сертификатов готов !\r\n"
fi

echo -e "\033[01;38mНастройка сетевых интерфейсов \033[00;37m...\r\n"
ip -br -c a
echo -e "\033[01;38mВыберите интерфейс:\033[00;37m\n"
ip -br a | grep -oE "eth[0-9]|wlan[0-9]" | awk '{print NR ") " $1}'
Inter=($(ip -br a | grep -oE "eth[0-9]|wlan[0-9]"))

read Choice
sudo iptables -I FORWARD -i ${Inter[$Choice-1]} -o tun0 -j ACCEPT
sudo iptables -I FORWARD -i tun0 -o ${Inter[$Choice-1]} -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o ${Inter[$Choice-1]} -j MASQUERADE 

ExternalIP=$(ip -br a | grep "${Inter[$Choice-1]}" | awk '{print $3}' | grep -oE "^[0-9.]{,3}+")
# echo $ExternalIP

sudo sysctl -w net.ipv4.ip_forward=1 &>/dev/null
# sudo iptables -L -v -n 
# sudo iptables -L -v -n  -t nat 
echo -e "\033[01;32m[ S ]\033[00;37m :: Сеть готова !\r\n"

echo -e "\033[01;38mНастройка сервера \033[00;37m...\r\n"
echo -e "local $ExternalIP
port 4444
proto udp
dev tun
ca /etc/openvpn/server/$SRVNAME/pki/ca.crt
cert /etc/openvpn/server/$SRVNAME/pki/issued/$SRVNAME.crt
key /etc/openvpn/server/$SRVNAME/pki/private/$SRVNAME.key
dh /etc/openvpn/server/$SRVNAME/pki/dh.pem
server 10.21.21.0 255.255.255.224
ifconfig-pool-persist /var/log/openvpn/ipp.txt
log /var/log/openvpn/log
log-append /var/log/openvpn/log
push \"redirect-gateway def1 bypass-dhcp\"
push \"dhcp-option DNS 8.8.8.8\"
keepalive 10 120
tls-auth /etc/openvpn/server/$SRVNAME/pki/ta.key 0
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn/status.log
verb 3
explicit-exit-notify 1" > /tmp/server.conf

echo -e "client
dev tun
port 4444
proto udp
remote $ExternalIP
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert $CLIENT.crt
key $CLIENT.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-CBC
verb 3" > /tmp/vpncl/client.conf

echo "<ca>" >> /tmp/vpncl/client.conf && cat /tmp/vpncl/ca.crt >> /tmp/vpncl/client.conf
echo "</ca>" >> /tmp/vpncl/client.conf

echo "<cert>" >> /tmp/vpncl/client.conf && tail -n +65 /tmp/vpncl/$CLIENT.crt >> /tmp/vpncl/client.conf
echo "</cert>" >> /tmp/vpncl/client.conf

echo "<key>" >> /tmp/vpncl/client.conf && cat /tmp/vpncl/$CLIENT.key >> /tmp/vpncl/client.conf
echo "</key>" >> /tmp/vpncl/client.conf

echo "<tls-auth>" >> /tmp/vpncl/client.conf && tail -n +4 /tmp/vpncl/ta.key >> /tmp/vpncl/client.conf
echo "</tls-auth>" >> /tmp/vpncl/client.conf

echo -e "[Unit]
Description=Демон OpenVPN сервера
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/server.conf --daemon
ExecReload=/usr/bin/kill -HUP $MAINPID
WorkingDirectory=/etc/openvpn

[Install]
WantedBy=multi-user.target" > /tmp/openvpn.service

sudo mv /tmp/server.conf /etc/openvpn/
sudo chown root:root /etc/openvpn/*.conf

sudo systemctl stop openvpn
sudo systemctl disable openvpn
sudo mv /tmp/openvpn.service /etc/systemd/system/
sudo systemctl enable openvpn
sudo systemctl restart openvpn

mv /tmp/vpncl/client.conf $HOME
mv $HOME/client.conf $HOME/$CLIENT.conf
rm -rf /tmp/vpncl
rm -rf /tmp/easyrsa

echo -e "\033[01;33m[ N ]\033[00;37m :: Логи сервера в файле /var/log/openvpn/log"
echo -e "\033[01;33m[ N ]\033[00;37m :: Профиль конфигурации клиента в файле $HOME/$CLIENT.conf"
echo -e "\033[01;32m[ S ]\033[00;37m :: Сервер готов, раздайте клиентам профили конфигурации!\r\n"
