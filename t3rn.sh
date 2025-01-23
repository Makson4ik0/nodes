channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

update_node() {
  delete_node

  if [ -d "$HOME/executor" ] || screen -list | grep -q "\.t3rnnode"; then
    echo 'Папка executor или сессия t3rnnode уже существуют. Установка невозможна. Выберите удалить ноду или выйти из скрипта.'
    return
  fi

  echo 'Начинаю обновление ноды...'

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY_LOCAL

  cd $HOME

  sudo wget https://github.com/t3rn/executor-release/releases/download/v0.46.0/executor-linux-v0.46.0.tar.gz -O executor-linux.tar.gz
  sudo tar -xzvf executor-linux.tar.gz
  sudo rm -rf executor-linux.tar.gz
  cd executor

  export NODE_ENV="testnet"
  export LOG_LEVEL="debug"
  export LOG_PRETTY="false"
  export EXECUTOR_PROCESS_ORDERS="true"
  export EXECUTOR_PROCESS_CLAIMS="true"
  export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"
  export ENABLED_NETWORKS="arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn"
  export RPC_ENDPOINTS_BSSP="https://base-sepolia-rpc.publicnode.com"
  export RPC_ENDPOINTS_L1RN="https://brn.calderarpc.com/"
  export RPC_ENDPOINTS_ARBT="https://api.zan.top/arb-sepolia"
  export EXECUTOR_MAX_L3_GAS_PRICE=150
  export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="false"

  cd $HOME/executor/executor/bin/

  screen -dmS t3rnnode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    cd $HOME/executor/executor/bin/
    ./executor

    exec bash
  '

  echo "Screen сессия 't3rnnode' создана и нода запущена..."
}

download_node() {
  if [ -d "$HOME/executor" ] || screen -list | grep -q "\.t3rnnode"; then
    echo 'Папка executor или сессия t3rnnode уже существуют. Установка невозможна. Выберите удалить ноду или выйти из скрипта.'
    return
  fi

  echo 'Начинаю установку ноды...'

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY_LOCAL

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install make screen build-essential software-properties-common curl git nano jq -y

  cd $HOME

  sudo wget https://github.com/t3rn/executor-release/releases/download/v0.38.0/executor-linux-v0.38.0.tar.gz -O executor-linux.tar.gz
  sudo tar -xzvf executor-linux.tar.gz
  sudo rm -rf executor-linux.tar.gz
  cd executor

  export NODE_ENV="testnet"
  export LOG_LEVEL="debug"
  export LOG_PRETTY="false"
  export EXECUTOR_PROCESS_ORDERS="true"
  export EXECUTOR_PROCESS_CLAIMS="true"
  export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"
  export ENABLED_NETWORKS="arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn"
  export RPC_ENDPOINTS_BSSP="https://base-sepolia-rpc.publicnode.com"
  export RPC_ENDPOINTS_L1RN="https://brn.calderarpc.com/"
  export RPC_ENDPOINTS_ARBT="https://api.zan.top/arb-sepolia"
  export EXECUTOR_MAX_L3_GAS_PRICE=105
  export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="false"

  cd $HOME/executor/executor/bin/

  screen -dmS t3rnnode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    cd $HOME/executor/executor/bin/
    ./executor

    exec bash
  '

  echo "Screen сессия 't3rnnode' создана и нода запущена..."
}

check_logs() {
  if screen -list | grep -q "\.t3rnnode"; then
    screen -S t3rnnode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
  else
    echo "Сессия t3rnnode не найдена."
  fi
}

change_fee() {
    echo 'Начинаю изменение комиссии...'

    if [ ! -d "$HOME/executor" ]; then
        echo 'Папка executor не найдена. Установите ноду.'
        return
    fi

    session="t3rnnode"

    read -p 'На какой газ GWEI вы хотите изменить? (по стандарту 105) ' GWEI_SET

    if screen -list | grep -q "\.${session}"; then
      screen -S "${session}" -p 0 -X stuff "^C"
      sleep 1
      screen -S "${session}" -p 0 -X stuff "export EXECUTOR_MAX_L3_GAS_PRICE=$GWEI_SET\n"
      sleep 1
      screen -S "${session}" -p 0 -X stuff "./executor\n"
      echo 'Комиссия была изменена.'
    else
      echo "Сессия ${session} не найдена. Газ не может поменяться"
      return
    fi
}

stop_node() {
  echo 'Начинаю остановку...'

  if screen -list | grep -q "\.t3rnnode"; then
    screen -S t3rnnode -p 0 -X stuff "^C"
    echo "Нода была остановлена."
  else
    echo "Сессия t3rnnode не найдена."
  fi
}

auto_restart_node() {
  if screen -list | grep -q "\.t3rnnode_auto"; then
    sudo screen -X -S t3rnnode_auto quit
    echo 'У вас уже был существующий скрин t3rnnode_auto. Он был удален'
  else
    echo 'Начинаю запуск...'
  fi

  screen -dmS t3rnnode_auto bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    while true; do
      restart_node
      sleep 7200
    done

    exec bash
  '

  echo "Screen сессия 't3rnnode_auto' создана и нода будет перезагружаться каждые 2 часа..."
}

restart_node() {
  echo 'Начинаю перезагрузку...'

  session="t3rnnode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "./executor\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

delete_node() {
  echo 'Начинаю удаление ноды...'

  if [ -d "$HOME/executor" ]; then
    sudo rm -rf $HOME/executor
    echo "Папка executor была удалена."
  else
    echo "Папка executor не найдена."
  fi

  if screen -list | grep -q "\.t3rnnode"; then
    sudo screen -X -S t3rnnode quit
    echo "Сессия t3rnnode была закрыта."
  else
    echo "Сессия t3rnnode не найдена."
  fi

  sudo screen -X -S t3rnnode_auto quit

  echo "Нода была удалена."
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🚀 Установить ноду"
    echo "2. 📋 Проверить логи ноды"
    echo "3. 🐾 Изменить комиссию"
    echo "4. 🛑 Остановить ноду"
    echo "5. 🔄 Перезапустить ноду"
    echo "6. 📈 Автоперезагрузка ноды"
    echo "7. ✅ Обновить ноду"
    echo "8. 🗑️ Удалить ноду"
    echo -e "9. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        change_fee
        ;;
      4)
        stop_node
        ;;
      5)
        restart_node
        ;;
      6)
        auto_restart_node
        ;;
      7)
        update_node
        ;;
      8)
        delete_node
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
