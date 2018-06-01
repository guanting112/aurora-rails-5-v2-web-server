#!/bin/bash

function run_script_init_system()
{
  setup_base
  setup_swap
}

function setup_base()
{

  echo "Update system locale" | shell_log
  export LC_ALL=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  sudo locale-gen zh_TW.UTF-8 en_US.UTF-8 
  echo -e "LC_ALL=\"en_US.UTF-8\"\nLANGUAGE=\"en_US.UTF-8\"\nLANG=\"en_US.UTF-8\"" | sudo tee /etc/default/locale > /dev/null
  sudo dpkg-reconfigure -f noninteractive locales 

  echo "Update timezone" | shell_log 
  echo "Asia/Taipei" | sudo tee /etc/timezone
  sudo cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
  sudo dpkg-reconfigure -f noninteractive tzdata 

  echo "Update and upgrade system" | shell_log
  sudo apt -y update 
  sudo apt -y upgrade 

  echo "Add HTTPS support to APT" | shell_log
  sudo apt install -y apt-transport-https ca-certificates 

  echo "Install basic software" | shell_log
  sudo apt install -y vim git tmux htop bmon ncdu iptraf pwgen dirmngr gnupg 
  sudo apt install -y git-core curl libffi-dev zlib1g-dev build-essential software-properties-common 
  sudo apt install -y libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 
  sudo apt install -y libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties 
  sudo apt install -y nodejs 

  echo "Setting Host Name Server" | shell_log
  echo -e "nameserver 1.1.1.1\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf > /dev/null
}

function setup_swap()
{
  echo "Update /swap size" | shell_log

  sudo dd if=/dev/zero of=/swap bs=1M count=1024
  sudo mkswap /swap
  sudo swapon /swap
}

run_script_init_system