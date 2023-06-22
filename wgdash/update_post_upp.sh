#!/bin/bash

# Параметры для дополнения
post_up_addition="iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE; iptables -A INPUT -p udp -m udp --dport 10086 -j ACCEPT"

# Проверка наличия файла и чтение его содержимого в переменную
config_file="wg0.conf"
if [[ -f "$config_file" ]]; then
  config_content=$(cat "$config_file")

  # Проверка, содержит ли строка PostUp уже правило INPUT
  if [[ $config_content =~ "iptables -A INPUT -p udp -m udp --dport 10086 -j ACCEPT" ]]; then
    echo "Правило INPUT уже добавлено в строку PostUp."
  else
    # Дополнение значения параметра PostUp
    updated_config_content="${config_content/PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE/PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE;$post_up_addition}"

    # Дополнение значения параметра PostUp в случае, если оно не найдено
    if [[ "$config_content" == "$updated_config_content" ]]; then
      updated_config_content="${config_content/PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE/PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE;$post_up_addition}"
    fi

    # Запись измененного содержимого обратно в файл
    echo "$updated_config_content" > "$config_file"

    echo "Значение PostUp с добавленным правилом INPUT добавлено в файл $config_file"
  fi
else
  echo "Файл $config_file не найден."
fi
