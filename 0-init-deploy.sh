#!/bin/sh

load_setting_file()
{
  . /tmp/aurora-rails-5-v2-web-server/0-machine-setting.sh
  rm /tmp/aurora-rails-5-v2-web-server/0-machine-setting.sh  
}

copy_setup_scripts()
{
  sudo cp -R /tmp/aurora-rails-5-v2-web-server/ /home/$DEPLOY_USER_NAME/aurora-rails-5-v2-web-server
  sudo rm -rfv /tmp/aurora-rails-5-v2-web-server/ > /dev/null
  sudo rm -rfv /home/$DEPLOY_USER_NAME/aurora-rails-5-v2-web-server/0-machine-setting.sh > /dev/null
  sudo rm -rfv /home/$DEPLOY_USER_NAME/aurora-rails-5-v2-web-server/0-init-deploy.sh > /dev/null
  sudo chown $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/aurora-rails-5-v2-web-server/*
  sudo chmod +x /home/$DEPLOY_USER_NAME/aurora-rails-5-v2-web-server/1-setup.sh
}

run_node_boot_script()
{
  export LC_ALL=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8

  load_setting_file
  load_setting
  add_deploy_user
  change_host_name
  write_ssh_key
  write_ssh_key_config
  write_ssh_authorized_keys
  copy_setup_scripts
  unset_variable
  all_done
}

write_ssh_key()
{
  sudo mkdir -p /home/$DEPLOY_USER_NAME/.ssh

  printf '%s' "$GIT_REPO_DEPLOY_PUBLIC_KEY_DATA" | sudo tee /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME.pub > /dev/null

  printf '%s' "$GIT_REPO_DEPLOY_PRIVATE_KEY_DATA" | sudo tee /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME > /dev/null

  sudo chown -R $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.ssh
  sudo chmod 700 /home/$DEPLOY_USER_NAME/.ssh

  sudo chown $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME.pub
  sudo chmod 644 /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME.pub

  sudo chown $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME
  sudo chmod 600 /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME
}

write_ssh_key_config()
{
  printf '%s' "$SSH_KEY_CONFIG" | sudo tee /home/$DEPLOY_USER_NAME/.ssh/config > /dev/null

  sudo chown -R $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.ssh/config
  sudo chmod 644 /home/$DEPLOY_USER_NAME/.ssh/config
}

write_ssh_authorized_keys()
{
  printf '%s' "$SSH_AUTHORIZED_KEYS" | sudo tee /home/$DEPLOY_USER_NAME/.ssh/authorized_keys > /dev/null
  sudo chown $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.ssh/authorized_keys 
}

random_text()
{
  local length=$1; [ -z $1 ] && length=12
  echo `tr -dc [:alnum:] < /dev/urandom | head -c $length`
}

new_host_name()
{
  local date_token="`date +%y%m%d`"
  local random_number="`tr -dc [:digit:] < /dev/urandom | head -c 4`"
  local new_name="$HOST_NODE_NAME_PREFIX-$date_token-$random_number"

  echo $new_name
}

change_host_name()
{
  local host_name="`new_host_name`"

  sudo hostnamectl set-hostname $host_name
  echo "127.0.0.1 $host_name.local $host_name" | sudo tee -a /etc/hosts > /dev/null
}

add_deploy_user()
{
  sudo useradd $DEPLOY_USER_NAME --create-home --shell /bin/bash 
  sudo addgroup $DEPLOY_USER_NAME sudo

  echo "$DEPLOY_USER_NAME:$DEPLOY_USER_PASSWORD" | sudo chpasswd -c SHA512

  echo "" | sudo tee /home/$DEPLOY_USER_NAME/.stickie > /dev/null

  printf '%s' "
SCRIPT_VERSION=$SCRIPT_VERSION
HOST_NEW_SSH_PORT=$HOST_NEW_SSH_PORT
DEPLOY_USER_NAME=$DEPLOY_USER_NAME
DEPLOY_USER_PASSWORD=$DEPLOY_USER_PASSWORD
SQL_MAIN_DATABASE_NAME=$SQL_MAIN_DATABASE_NAME
SQL_ROOT_PASSWORD=$SQL_ROOT_PASSWORD
SQL_MAINTENANCE_USERNAME=$SQL_MAINTENANCE_USERNAME
SQL_MAINTENANCE_PASSWORD=$SQL_MAINTENANCE_PASSWORD
SQL_BACKUP_USERNAME=$SQL_BACKUP_USERNAME
SQL_BACKUP_PASSWORD=$SQL_BACKUP_PASSWORD
" | sudo tee /home/$DEPLOY_USER_NAME/.stickie > /dev/null

  sudo chown -R $DEPLOY_USER_NAME:$DEPLOY_USER_NAME /home/$DEPLOY_USER_NAME/.stickie
  sudo chmod 0400 /home/$DEPLOY_USER_NAME/.stickie

  echo "New User Account ( for Application ) "
  echo "$DEPLOY_USER_NAME"
  echo "$DEPLOY_USER_PASSWORD"
}

unset_variable()
{
  unset HOST_NODE_NAME_PREFIX

  unset DEPLOY_USER_NAME
  unset DEPLOY_USER_PASSWORD

  unset SQL_MAIN_DATABASE_NAME
  unset SQL_ROOT_PASSWORD
  unset SQL_MAINTENANCE_USERNAME
  unset SQL_MAINTENANCE_PASSWORD
  unset SQL_BACKUP_USERNAME
  unset SQL_BACKUP_PASSWORD

  unset GIT_REPO_DEPLOY_PRIVATE_KEY_NAME
  unset GIT_REPO_DEPLOY_PUBLIC_KEY_DATA
  unset GIT_REPO_DEPLOY_PRIVATE_KEY_DATA
  unset SSH_KEY_CONFIG
}

all_done()
{
  echo '-----------------------------------------------------'
  echo "System: Done, You need to login first [use apps user]"
  echo '-----------------------------------------------------'
}

run_node_boot_script