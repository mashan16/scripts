#!/bin/bash
#
# metadata_begin
# recipe: Xray X-UI
# tags: alma9,debian11,debian12,fedora,centos8,centos9,centos9-stream,oracle8,oracle9,rocky9,ubuntu2004,ubuntu2204,ubuntu2404
# revision: 3
# description_ru: Рецепт установки Xray X-UI
# description_en: Recipe for installing the Xray X-UI
# metadata_end
#

RNAME="Xray_X-UI"

set -x

LOG_PIPE=/tmp/log.pipe.$$
mkfifo ${LOG_PIPE}
LOG_FILE=/root/${RNAME}.log
touch ${LOG_FILE}
chmod 600 ${LOG_FILE}
tee < ${LOG_PIPE} ${LOG_FILE} &
exec > ${LOG_PIPE}
exec 2> ${LOG_PIPE}

killjobs() {
    test -n "$(jobs -p)" && kill $(jobs -p) || :
}
trap killjobs INT TERM EXIT

echo
echo "== Recipe ${RNAME} started at $(date) =="
echo

# Переменные
X_UI_INSTALL_SCRIPT="https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh"

# Определение IP-адресов и сетевой карты
ipv4Addr=$(ip route get 1 | grep -Po '(?<=src )[^ ]+')

# Информация об ОС
. /etc/os-release
osLike="${ID_LIKE}"
[ "${ID}" = "debian" ] && osLike="debian"
echo ${ID_LIKE} | grep -q "rhel\|fedora" && osLike="rhel"
[ "${ID}" = "fedora" ] && osLike="rhel"
unaID=$(echo ${VERSION_ID} | sed -r 's/\..+//')

# Определение пакетного менеджера
DNF="/usr/bin/yum"
[ -f /usr/bin/dnf ] && DNF="/usr/bin/dnf"
[ -f /usr/bin/apt ] && { export DEBIAN_FRONTEND=noninteractive ; DNF="apt_Installer" ; }
[ -n "${DNF}" ] || exit 1

# Финальный текст
final_text() {
. /root/info.txt
cat > /root/${RNAME}-final.txt <<- EOF
=========================
Работа скрипта ${RNAME} успешно завершена.
Журнал выполнения вы можете посмотреть в файле /root/${RNAME}.log
Перейдите по адресу "http://${ipv4Addr}:${port}${webBasePath}" для входа в панель
Имя пользователя: ${username}
Пароль: ${password}
=========================

=========================
The ${RNAME} script completed successfully.
You can see the execution log in /root/${RNAME}.log.
Go to the "http://${ipv4Addr}:${port}${webBasePath}" to login
Login: ${username}
Password: ${password}
=========================
EOF
rm -rf /root/info.txt || return 0
}

# Определяем инсталятор apt и его опции. Обходим фоновые задачи установки и одновления ОС
apt_Installer() {
while ps uxaww | grep -v grep | grep -Eq 'apt|dpkg|unattended' ; do echo "waiting..." ; sleep 5 ; done && \
/usr/bin/apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" -q 	--allow-downgrades --allow-remove-essential --allow-change-held-packages $@
}

# Установка основных программ и подготовка базовых репозиториев
install_soft() {
if [ "${osLike}" = "debian" ]; then
	[ $(systemctl is-active unattended-upgrades.service 2>/dev/null) = "active" ] && { systemctl stop unattended-upgrades.service && unattServ="1" ; }
	${DNF} update && ${DNF} -y install wget || { echo "Can not preinstall soft" && exit 1 ; }
fi
if [ "${osLike}" = "rhel" ]; then
	${DNF} -y install wget || { echo "Can not preinstall soft" && exit 1 ; }
fi
${DNF} -y install tuned
systemctl enable --now tuned 2>/dev/null || return 0
}

# Определение и настройка фаервола
config_firewall() {
([ -f /usr/sbin/ufw ] && $(ufw status | grep -i "Status" | grep -qi " active\|enable")) && ufw allow 54321/tcp
if [ -f /usr/sbin/firewalld -a $(systemctl is-active firewalld.service 2>/dev/null) = "active" ]; then
	firewalldZone="$(firewall-cmd --get-default-zone)"
	[ ! -f /usr/lib/firewalld/services/ispmanager.xml ] && \
	cat << 'EOF' > /etc/firewalld/services/x-ui.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>x-ui</short>
  <description>X-UI rule</description>
  <port protocol="tcp" port="54321"/>
</service>
EOF
	firewall-cmd --reload
	firewall-cmd --permanent --zone=${firewalldZone} --remove-service=dhcpv6-client 2>&1 >/dev/null || return 0
	firewall-cmd --permanent --zone=${firewalldZone} --add-service=x-ui
	firewall-cmd --reload
fi
}

# Установка X-UI
install_x_ui() {
wget -O /root/x-ui_install.sh ${X_UI_INSTALL_SCRIPT} || { echo "Can not download install script" && exit 1 ; }
/bin/bash /root/x-ui_install.sh || { echo "Can not install script" && exit 1 ; }
x-ui enable
x-ui settings | grep 'username\|password\|port\|webBasePath' | sed 's/:\ /="/ ; s/\ // ; s/$/"/ ; s/\x1b\[[0-9;]*m//g' > /root/info.txt
}

install_soft
install_x_ui
[ -n "${unattServ}" ] && { systemctl start unattended-upgrades.service ; }
config_firewall
final_text