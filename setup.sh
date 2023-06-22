#!/bin/bash
# �������� ������� IP-�����
MYHOST_IP=$(hostname -I | cut -d' ' -f1)
# ���������� �������
printf "\e[42m���������� �������...\e[0m\n"
apt update
printf "\e[42m������ ������� ���������.\e[0m\n"

# ��������� Git
printf "\e[42m��������� Git...\e[0m\n"
apt install git -y
printf "\e[42mGit ������� ����������.\e[0m\n"

# ��������� Git
printf "\e[42m��������� SUDO...\e[0m\n"
apt install sudo -y
printf "\e[42mSUDO ������� ����������.\e[0m\n"

# ������������ �����������
printf "\e[42m������������ ����������� dwg-ui...\e[0m\n"
git clone https://github.com/dignezzz/dwg-ui.git temp

if [ ! -d "dwg-ui" ]; then
  mkdir dwg-ui
  echo "����� dwg-ui �������."
else
  echo "����� dwg-ui ��� ����������."
fi

# ����������� ����������� ��������� ���������� � ������� ���������� � ����������� ������������ ������ � �����
cp -rf temp/* dwg-ui/

# �������� ��������� ���������� �� ���� �� ����������
rm -rf temp
printf "\e[42m����������� dwg-ui ������� ���������� �� ���������� ������ � �����������.\e[0m\n"

# ��������� � ����� ad-wireguard
printf "\e[42m��������� � ����� dwg-ui...\e[0m\n"
cd dwg-ui
printf "\e[42m������� � ����� dwg-ui\e[0m\n"

# ��������� ���� �� ���� ���������
printf "\e[42m��������� ���� �� ���� ���������...\e[0m\n"
chmod +x install.sh
printf "\e[42m����� �� ���� ��������� ����������.\e[0m\n"

# ������ ���������
printf "\e[42m������ ��������� ad-wireguard...\e[0m\n"
./install.sh
printf "\e[42m��������� ad-wireguard ������� ���������.\e[0m\n"

# ��������� ���� �� ���������� tools
printf "\e[42m��������� ���� �� ���������� tools...\e[0m\n"
chmod +x -R tools
printf "\e[42m����� �� ���������� tools ������� �����������.\e[0m\n"

# ������ ������� ssh.sh
printf "\e[42m������ ������� ssh.sh ��� ����� ������������ ����� SSH...\e[0m\n"
./tools/ssh.sh
printf "\e[42m������ ssh.sh ������� ��������.\e[0m\n"

# ������ ������� ufw.sh
printf "\e[42m������ ������� ufw.sh ��� ��������� UFW Firewall...\e[0m\n"
./tools/ufw.sh
printf "\e[42m������ ufw.sh ������� ��������.\e[0m\n"

printf "������ ��������� ������ wg-ru.sh ��� ����������� � ������������ ����������?? (Y/n) (�� ��������� - Y, ������ ������ Enter): "
read choice_ru

if [[ $choice_ru == "" || $choice_ru == "Y" || $choice_ru == "y" ]]; then
  ./tools/wg-ru.sh
else
  printf "������ �� ����� �������.\n"
fi

# ��������� � ����� /
printf "\e[42m��������� � ����� /root/...\e[0m\n"
cd
printf "\e[42m������� � ����� /root/ \e[0m\n"

printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
printf '\e[48;5;202m\e[30m �� �����������! \e[0m\n'
printf "\e[48;5;202m\e[30m ����� ����� � ���-��������� WireGuard ����� ���������: http://$MYHOST_IP:51821 \e[0m\n"
printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
printf '\e[48;5;202m\e[30m �� ������ �������� ���������� UFW-Docker, ��� �������� ���-���������� wireguard. \e[0m\n'
printf '\e[48;5;196m\e[97m ��������! ��������� ������ ����� ���� ��� ��������� ��� ���� ������� � WireGUARD!!! \e[0m\n'
printf '\e[48;5;202m\e[30m ������� ��� ���������: ./dwg-ui/tools/ufw-docker.sh \e[0m\n'
printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
printf '\e[48;5;202m\e[30m ���� ��� ���������� ��� ������, �� ������ ���� ������������� ������ �� ���� ����������: https://yoomoney.ru/to/41001707910216 \e[0m\n'
