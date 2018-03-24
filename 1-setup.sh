#!/bin/bash

#
# Bash Helper
#
function shell_message() { local note="$1";        awk '{ print "\033[37m[","'$note'","]","=>",$0,"\033[m" }'; }
function shell_log()     { local note="run";       awk '{ print "\033[1;33;44m[","'$note'","]","=>",$0,"\033[m" }'; }
function shell_error()   { local note="error";     awk '{ print "\033[1;5;33;41m[","'$note'","]","=>",$0,"\033[m" }'; }
function important()     { local note="important"; awk '{ print "\033[1;31m[","'$note'","]","=>",$0,"\033[m" }'; }
function all_done()      { local note="done";      awk '{ print "\033[1;5;32m[","'$note'","]","=>",$0,"\033[m" }'; }

#
# Script
#
function show_banner()
{
  printf "\n\e[1;36mAurora Rails 5 (v2) Web Server (by Guanting Chen)\e[m\n"
  printf "\e[36m<4dev/> $(whoami)@$(hostname) $(date); Script Loaded.\e[m\n\n"
}

function clear_histoy()
{
  echo "Clear histoy" | important

  history -c
  sudo rm -rfv ~/.*_history | shell_message rm
  sudo rm -rfv /root/.*_history | shell_message rm
}

function active_sudo_and_get_stickie()
{
  source ~/.stickie

  echo $DEPLOY_USER_PASSWORD | sudo --stdin --validate && echo 'sudo-validate-ok'
}

function start_setup()
{
  show_banner

  echo 'Are you sure you want to install (yes/no) ?' | shell_message "Install/Start"

  read yes_or_no

  if [ "$yes_or_no" == 'yes' ]
  then

    echo 'Update sudo validate' | important

    local active_sudo_status="`active_sudo_and_get_stickie`"

    if [ $active_sudo_status == 'sudo-validate-ok' ]; then
      start_setup_base_system
      start_setup_dev_profile
      start_setup_ruby
      install_other_packages
    else
      echo "Require administrative privileges" | important
    fi

  fi
}

function install_other_packages() {
  local ruby_install_status="`check_ruby_setup`"

  if [ $ruby_install_status == 'NEW_RUBY_INSTALLED' ]
  then
    start_setup_rails
    start_setup_nginx_and_passenger
    start_setup_database
    start_setup_security_hardening
    clear_histoy
    date | all_done
  else
    echo "Ruby is not installed" | shell_error
  fi
}

function setup_software_from_shell()
{
  local shell_file_name=$1
  local shell_file_path=~/aurora-rails-5-v2-web-server/$shell_file_name

  echo 'Update sudo validate' | important

  local active_sudo_status="`active_sudo_and_get_stickie`"

  if [ $active_sudo_status == 'sudo-validate-ok' ]; then
    if [ -f $shell_file_path ] && [ -s $shell_file_path ]
    then
      echo "Start Script [$shell_file_path] " | important

      chmod +x $shell_file_path
      source $shell_file_path
    else
      echo "$shell_file_name is not found" | shell_error
      exit
    fi
  else
    echo "Require administrative privileges" | important
    exit
  fi

  echo "Clear history" | important

  echo "Remove shell script" | important
  rm -rfv $shell_file_path | shell_message rm

  history -c
}

function start_setup_base_system()
{
  setup_software_from_shell "1-update-system.sh"
}

function start_setup_dev_profile()
{
  echo "Setup Dev Profile" | shell_log

  cp ~/aurora-rails-5-v2-web-server/1-install-dev-profile.sh ~/.dev_profile
  echo 'source "$HOME/.dev_profile"' >> ~/.bash_profile && source ~/.bash_profile
  echo -e ':set number\n:syntax on' > ~/.vimrc 
}

function start_setup_ruby()
{
  setup_software_from_shell "2-install-ruby.sh"
}

function check_ruby_setup()
{
  if [[ "`which gem`" =~ '/.rbenv' ]]
  then
    echo "NEW_RUBY_INSTALLED"
  else
    echo "NEW_RUBY_NOT_FOUND"
  fi
}

function start_setup_rails()
{
  setup_software_from_shell "3-install-rails-and-important-gems.sh"
}

function start_setup_nginx_and_passenger()
{
  setup_software_from_shell "4-install-nginx-and-passenger.sh"
}

function start_setup_database()
{
  setup_software_from_shell "5-install-database.sh"
}

function start_setup_security_hardening()
{
  setup_software_from_shell "6-basic-system-hardening.sh"
}

start_setup