#!/bin/bash

function load_setting()
{
  source ~/.stickie
}

function fix_sshd_config()
{
  if [ ! -f /etc/ssh/sshd_config.example ]; then
    echo "Backup sshd config file" | shell_log
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.example
  fi

  echo "Modify sshd config" | shell_log
  sudo sed -r "s:^Port[^$]+$:Port $HOST_NEW_SSH_PORT:g" -i /etc/ssh/sshd_config
  sudo sed -r 's:^PermitRootLogin[^$]+$:PermitRootLogin without-password:g' -i /etc/ssh/sshd_config
  sudo sed -r 's:^PermitEmptyPasswords[^$]+$:PermitEmptyPasswords no:g' -i /etc/ssh/sshd_config
  echo -e "\nAllowUsers $DEPLOY_USER_NAME\n" | sudo tee -a /etc/ssh/sshd_config > /dev/null
}

function reload_sshd()
{
  echo "Reload SSH Deamon" | shell_log
  sudo reload ssh
}

function add_reboot_not_use_sudo_to_apps_user()
{
  printf '%s' '
[DEPLOY_USER_NAME] ALL=NOPASSWD:/sbin/reboot
' | sudo tee /etc/sudoers.d/$DEPLOY_USER_NAME > /dev/null

  sudo sed -r "s:\[DEPLOY_USER_NAME\]:$DEPLOY_USER_NAME:g" /etc/sudoers.d/$DEPLOY_USER_NAME
}

function run_script_system_hardening()
{
  add_reboot_not_use_sudo_to_apps_user
  load_setting
  fix_sshd_config
  reload_sshd
}

run_script_system_hardening