#!/bin/bash

if grep -q "VERSION_ID=\"10\"" /etc/os-release; then
  echo "Этот скрипт не может быть выполнен на Debian 10."
  exit 1
fi

# Здесь идет код скрипта, который должен быть выполнен на всех системах, кроме Debian 10

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Проверяем, выполняется ли скрипт от имени пользователя root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Запустите скрипт с правами root${NC}"
  exit
fi

# Проверяем, установлен ли Docker
if [ -x "$(command -v docker)" ]; then
  echo -e "${GREEN}Docker уже установлен${NC}"
else
  # Проверяем, какое распределение используется, и устанавливаем необходимые зависимости
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  elif [ -f /etc/redhat-release ]; then
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y curl
  else
    echo -e "${RED}Неподдерживаемое распределение${NC}"
    exit
  fi

  # Устанавливаем Docker
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh

  # Запускаем и включаем службу Docker
  systemctl start docker
  systemctl enable docker

  echo -e "${GREEN}Docker успешно установлен${NC}"
fi

# Проверка наличия docker-compose
if command -v docker-compose &> /dev/null
then
    printf "${GREEN}Docker Compose уже установлен\n${NC}"
else
    # Установка docker-compose
    curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose &&
    chmod +x /usr/local/bin/docker-compose

    # Проверка успешности установки
    if [ $? -eq 0 ]; then
        printf "${GREEN}Установка Docker Compose завершена успешно\n${NC}"
    else
        printf "${GREEN}Ошибка при установке Docker Compose\n${NC}"
        printf "${YELLOW}Хотите продолжить выполнение скрипта? (y/n): ${NC}"
        read choice
        case "$choice" in
            y|Y )
                printf "${GREEN}Продолжение выполнения скрипта\n${NC}"
                ;;
            n|N )
                printf "${RED}Завершение выполнения скрипта\n${NC}"
                exit 1
                ;;
            * )
                printf "${RED}Неверный выбор. Завершение выполнения скрипта\n${NC}"
                exit 1
                ;;
        esac
    fi
fi

# Устанавливаем редактор Nano
if ! command -v nano &> /dev/null
then
    read -p "Хотите установить текстовый редактор Nano? (y/n) " INSTALL_NANO
    if [ "$INSTALL_NANO" == "y" ]; then
        apt-get update
        apt-get install -y nano
    fi
else
    echo "Текстовый редактор Nano уже установлен."
fi

# Проверяем есть ли контейнер с именем wireguard

printf "${BLUE} Сейчас проверим свободен ли порт 51821 и не установлен ли другой wireguard.\n${NC}"

if [[ $(docker ps -q --filter "name=wireguard") ]]; then
    printf "!!!!>>> Другой Wireguard контейнер уже запущен, и вероятно занимает порт 51821. Пожалуйста удалите его и запустите скрипт заново\n "
    printf "${RED} !!!!>>> Завершаю скрипт! \n${NC}"
    exit 1
else
    printf "Wireguard контейнер не запущен в докер. Можно продолжать\n"
    # Проверка, запущен ли контейнер, использующий порт 51821
    if lsof -Pi :51821 -sTCP:LISTEN -t >/dev/null ; then
        printf "${RED}!!!!>>> Порт 51821 уже используется контейнером.!\n ${NC}"
        if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "wg-easy.*:51821->" ; then
            printf "WG-EASY контейнер использует порт 51821. Хотите продолжить установку? (y/n): "
            read -r choice
            case "$choice" in 
              y|Y ) printf "Продолжаем установку...\n" ;;
              n|N ) printf "${RED} ******* Завершаю скрипт!\n ${NC}" ; exit 1;;
              * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
            esac
        else
            printf "${RED} ******* Завершаю скрипт!\n ${NC}"
            exit 1
        fi
    else
        printf "Порт 51821 свободен.\n"
        printf "Хотите продолжить установку? (y/n): "
        read -r choice
        case "$choice" in 
          y|Y ) printf "Продолжаем установку...\n" ;;
          n|N ) printf "Установка остановлена.${NC}" ; exit 1;;
          * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
        esac
    fi
fi

printf "${GREEN} Этап проверки докера закончен, можно продолжить установку\n${NC}"

# Получаем внешний IP-адрес
MYHOST_IP=$(hostname -I | cut -d' ' -f1)

# Записываем IP-адрес в файл docker-compose.yml с меткой MYHOSTIP
sed -i -E  "s/- SERVER_IP=.*/- SERVER_IP=$MYHOST_IP/g" docker-compose.yml

# Даем пользователю информацию по установке
# Читаем текущие значения из файла docker-compose.yml
CURRENT_WG_HOST=$(grep WG_HOST docker-compose.yml | cut -d= -f2)

# Выводим текущие значения
echo ""
echo -e "${BLUE}Текущие значения:${NC}"
echo ""
echo -e "IP адрес сервера: ${BLUE}$CURRENT_WG_HOST${NC}"
echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${YELLOW}http://$CURRENT_WG_HOST:10086${NC}"
echo ""

# Устанавливаем apache2-utils, если она не установлена
if ! [ -x "$(command -v htpasswd)" ]; then
  echo -e "${RED}Установка apache2-utils...${NC}" >&2
   apt-get update
   apt-get install apache2-utils -y
fi

# Если логин не введен, устанавливаем логин по умолчанию "admin"
while true; do
  echo -e "${YELLOW}Введите логин (только латинские буквы и цифры), если пропустить шаг будет задан логин admin:${NC}"  
  read username
  if [ -z "$username" ]; then
    username="admin"
    break
  fi
  if ! [[ "$username" =~ [^a-zA-Z0-9] ]]; then
    break
  else
    echo -e "${RED}Логин должен содержать только латинские буквы и цифры.${NC}"
  fi
done

# Запрашиваем у пользователя пароль
while true; do
  echo -e "${YELLOW}Введите пароль (если нажать Enter, пароль будет задан по умолчанию admin):${NC}"  
  read password
  if [ -z "$password" ]; then
    password="admin"
    break
  fi
  if ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
    break
  else
    echo -e "${RED}Пароль должен содержать латинские буквы верхнего и нижнего регистра, цифры.${NC}"
  fi
done

# Генерируем хеш пароля с помощью htpasswd из пакета apache2-utils
hashed_password=$(htpasswd -nbB $username "$password" | cut -d ":" -f 2)

# Экранируем символы / и & в hashed_password
hashed_password=$(echo "$hashed_password" | sed -e 's/[\/&]/\\&/g')

# Проверяем наличие файла AdGuardHome.yaml и его доступность для записи
if [ ! -w "adguardhome/conf/AdGuardHome.yaml" ]; then
  echo -e "${RED}Файл adguardhome/conf/AdGuardHome.yaml не существует или не доступен для записи.${NC}" >&2
  exit 1
fi

# Записываем связку логина и зашифрованного пароля в файл conf/AdGuardHome.yaml
if 
#  sed -i "s/\(name: $username\).*\(password: \).*/\1\n\2$hashed_password/" conf/AdGuardHome.yaml 
  sed -i -E "s/- name: .*/- name: $username/g" adguardhome/conf/AdGuardHome.yaml
  sed -i -E "s/password: .*/password: $hashed_password/g" adguardhome/conf/AdGuardHome.yaml
then
  # Выводим сообщение об успешной записи связки логина и пароля в файл
  echo -e "${GREEN}Связка логина и пароля успешно записана в файл adguardhome/conf/AdGuardHome.yaml${NC}"
else
  echo -e "${RED}Не удалось записать связку логина и пароля в файл adguardhome/conf/AdGuardHome.yaml.${NC}" >&2
  exit 1
fi

# Генерация нового значения для переменной PRIVATE_KEY
new_private_key=$(wg genkey)

# Проверка наличия файла и чтение его содержимого в переменную
config_file="./wgdash/conf/wg0.conf"
if [[ -f "$config_file" ]]; then
  config_content=$(cat "$config_file")
  # Замена значения переменной PRIVATE_KEY в содержимом файла
  new_config_content=${config_content//\$PRIVATE_KEY/$new_private_key}
  # Запись измененного содержимого обратно в файл
  echo "$new_config_content" > "$config_file"
  echo "Значение PRIVATE_KEY заменено в файле $config_file"
fi

# Выводим связку логина и пароля в консоль
echo "Ниже представлены логин и пароль для входа в AdGuardHome"
echo -e "${GREEN}Логин: $username${NC}"
echo -e "${GREEN}Пароль: $password${NC}"

# Запускаем docker-compose
docker-compose up -d

echo ""
echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${BLUE}http://$CURRENT_WG_HOST:10086${NC}"
echo -e "Адрес входа после настройки UFW-Docker, для подключения к Wireguard: ${BLUE}http://10.2.0.3:10086${NC}"
echo -e "Логин от веб-интерфейса: admin"
echo -e "Пароль от веб-интерфейса: admin"
echo ""
echo -e "Адрес входа в веб-интерфейс AdGuardHome после установки (только когда подключитесь к сети WireGuard!!!): ${BLUE}http://10.2.0.100${NC}"
echo "Ниже представлены логин и пароль для входа в AdGuardHome"
echo -e "Логин:${BLUE} $username${NC}"
echo -e "Пароль:${BLUE} $password${NC}"
