#!/usr/bin/env bash

function load_toolkit_setting()
{
  NGINX_SITES_CONF_PATH=/etc/nginx/sites-available
  NGINX_SITES_ENABLED_PATH=/etc/nginx/sites-enabled
}

#
# Bash Helper
#
function shell_message() { local note="$1"; awk '{ print "\033[37m[","'$note'","]","=>",$0,"\033[m" }'; }
function shell_log() { local note="script/run"; awk '{ print "\033[1;33;44m[","'$note'","]","=>",$0,"\033[m" }'; }
function shell_error() { local note="error"; awk '{ print "\033[1;5;33;41m[","'$note'","]","=>",$0,"\033[m" }'; }
function important() { local note="important"; awk '{ print "\033[1;31m[","'$note'","]","=>",$0,"\033[m" }'; }
function all_done() { local note="done"; awk '{ print "\033[1;5;32m[","'$note'","]","=>",$0,"\033[m" }'; }

function tips()
{
  printf "%s" '
  -- Bash Helper --
  $ random_text [Length]                    # Random Password/Text Generator (default length 12)
  $ update_sudo                             # Validate sudo (via .stickie file)
  
  -- Rails and Passenger Helper --
  $ create_rails_website_in_nginx           # Create Rails website conf with nginx
  $ restart_rails                           # Restart rails app (via touch file)
  $ restart_passenger                       # Restart rails app (via passenger)

  -- Nginx Server --
  $ list_nginx_sites                        # List all nginx sites configuration
  $ disable_nginx_website                   # Disable nginx website
  $ enable_nginx_website                    # Enable nginx website
  $ destroy_nginx_website_conf              # Destroy nginx website Conf

  $ setting_nginx                           # Setting nginx main configuration file (via vi)
  $ restart_nginx                           # Restart nginx server
  $ reload_nginx                            # Reloading the configuration file
  $ start_nginx                             # Start nginx server
  $ stop_nginx                              # Stop nginx server
  $ reset_nginx_log                         # 
  $ test_nginx                              # Check nginx configuration file

'
}

function random_text ()
{
  local length=$1

  if [ -z $1 ]; then length=12; fi

  echo `tr -dc [:alnum:] < /dev/urandom | head -c $length`
}

function check_sudo()
{
  echo $1 | sudo --stdin --validate 2>/dev/null && echo 'sudo-validate-ok'
}

function update_sudo()
{
  local account_password=''

  if [ -f ~/.stickie ]; then
    source ~/.stickie
    account_password="$DEPLOY_USER_PASSWORD"
  else
    echo "system needs $(whoami)'s Password: " | shell_message read
    read -s temp_password
    account_password="$temp_password"
  fi
  
  local check_status="`check_sudo $account_password`"

  if [ "$check_status" == "sudo-validate-ok" ]; then
    echo "sudo is validated" | important
  else
    echo "require administrative privileges" | shell_error
  fi
}

# 
# Rails Helper
# 
function restart_rails()
{
  local restart_file_path=tmp/restart.txt

  if [ -f ./Gemfile ] && [ -d ./tmp/ ]
  then
    if [ -f ./$restart_file_path ]
    then
      echo "remove old restart.txt " | shell_message rm
      rm ./$restart_file_path
    fi

    echo "add new file <restart.txt> " | shell_message touch
    touch ./$restart_file_path
  else
    echo "not a rails application" | shell_error
  fi
}

function restart_passenger()
{
  update_sudo
  sudo passenger-config restart-app
  printf "\033[0m"
}

# 
# Nginx Helper
# 
function binding_server_short_command()
{
  alias setting_nginx='update_sudo; sudo vi /etc/nginx/nginx.conf '
  alias restart_nginx='update_sudo; sudo service nginx restart '
  alias reload_nginx='update_sudo; sudo service nginx reload '
  alias start_nginx='update_sudo; sudo service nginx start '
  alias stop_nginx='update_sudo; sudo service nginx stop '
  alias reset_nginx_log='update_sudo; sudo service nginx rotate '
  alias test_nginx='update_sudo; sudo nginx -t '
}

binding_server_short_command

function list_nginx_sites()
{
  echo $NGINX_SITES_CONF_PATH | shell_log
  ls -al $NGINX_SITES_CONF_PATH | shell_message ls
  echo $NGINX_SITES_ENABLED_PATH | shell_log
  ls -al $NGINX_SITES_ENABLED_PATH | shell_message ls
}

function create_rails_website_in_nginx()
{
  local usage_tips="Usage:\tcreate_rails_website_in_nginx PROJECT_NAME DOMAIN_NAME [PUBLIC_DIR_PATH] \nEx:\t\tcreate_rails_website_in_nginx demo_app demo.example.com current/public"

  local project_name=$1
  local project_domain=$2
  local project_path=$HOME/$project_name
  local project_app_public_root_path=$3

  if [ -z "$project_name" ]   ; then echo -e $usage_tips | expand --tabs=4; return 9; fi
  if [ -z "$project_domain" ] ; then echo -e $usage_tips | expand --tabs=4; return 9; fi

  check_rails_project_template_in_nginx

  if [ -z "$project_app_public_root_path" ] ; then
    project_app_public_root_path=$project_path/public
  else
    project_app_public_root_path=$project_path/$3
  fi

  echo -e "Project Name:\t$project_name" | shell_message info
  echo -e "Domain Name:\t$project_domain" | shell_message info
  echo -e "Public Path:\t$project_app_public_root_path" | shell_message info

  echo "Create Rails configuration file" | shell_log
  sudo cp $NGINX_SITES_CONF_PATH/rails.example $NGINX_SITES_CONF_PATH/$project_name
  sudo sed -r "s:\[DOMAIN_NAME\]:$project_domain:g" -i $NGINX_SITES_CONF_PATH/$project_name
  sudo sed -r "s:\[PUBLIC_ROOT\]:$project_app_public_root_path:g" -i $NGINX_SITES_CONF_PATH/$project_name

  if [ -f $NGINX_SITES_ENABLED_PATH/$project_name ]; then
    echo "Unlink old website configuration" | shell_message run
    sudo rm -v $NGINX_SITES_ENABLED_PATH/$project_name | shell_message rm
  fi

  sudo ln -s $NGINX_SITES_CONF_PATH/$project_name $NGINX_SITES_ENABLED_PATH/$project_name

  echo -e "Conf:\t$NGINX_SITES_CONF_PATH/$project_name" | shell_message info

  echo "Link/new nginx website configuration" | shell_log
  echo 'You still need to restart nginx server.' | all_done
}

function disable_nginx_website()
{
  local usage_tips="Usage:\tdisable_nginx_website PROJECT_NAME or DOMAIN_NAME\nEx:\t\tdisable_nginx_website demo_app\n"

  local conf_name=$1

  if [ -z "$conf_name" ]; then echo -e $usage_tips | expand --tabs=4; return 9; fi

  update_sudo

  if [ -f $NGINX_SITES_ENABLED_PATH/$conf_name ]; then
    echo "Unlink website setting. <$conf_name> " | shell_log
    sudo rm -v $NGINX_SITES_ENABLED_PATH/$conf_name | shell_message rm
  else
    echo "Website configuration not found" | shell_error
  fi
}

function enable_nginx_website()
{
  local usage_tips="Usage:\tenable_nginx_website PROJECT_NAME or DOMAIN_NAME\nEx:\t\tenable_nginx_website demo_app\n"

  local conf_name=$1

  if [ -z "$conf_name" ]; then echo -e $usage_tips | expand --tabs=4; return 9; fi

  update_sudo

  if [ -f $NGINX_SITES_CONF_PATH/$conf_name ]; then
    if [ -f $NGINX_SITES_ENABLED_PATH/$conf_name ]; then
      sudo rm $NGINX_SITES_ENABLED_PATH/$conf_name
    fi

    sudo ln -s $NGINX_SITES_CONF_PATH/$conf_name $NGINX_SITES_ENABLED_PATH/$conf_name

    echo "Link website setting. [$conf_name] " | shell_message run
    echo "Done" | shell_message run
  else
    echo "Website configuration not found" | shell_error
  fi
}

function destroy_nginx_website_conf()
{
  local usage_tips="Usage:\tdestroy_nginx_website_conf PROJECT_NAME or DOMAIN_NAME\nEx:\t\tdestroy_nginx_website_conf demo_app\n"

  local conf_name=$1

  if [ -z "$conf_name" ]; then echo -e $usage_tips | expand --tabs=4; return 9; fi

  update_sudo

  if [ -f $NGINX_SITES_ENABLED_PATH/$conf_name ]; then
    echo "Unlink website setting. <$conf_name>" | shell_message rm
    sudo rm -v $NGINX_SITES_ENABLED_PATH/$conf_name | shell_message rm
  fi

  if [ -f $NGINX_SITES_CONF_PATH/$conf_name ]; then
    echo "Delete website setting. <$conf_name>" | shell_message rm
    sudo rm -v $NGINX_SITES_CONF_PATH/$conf_name | shell_message rm
  fi
}

function check_rails_project_template_in_nginx()
{
  update_sudo
  create_rails_project_template_to_nginx
}

function create_rails_project_template_to_nginx()
{
  echo 'Create rails project template to nginx.' | shell_log

printf '%s' '
server {
  server_name [DOMAIN_NAME] *.[DOMAIN_NAME];
  root        [PUBLIC_ROOT];

  if ( $http_user_agent ~* (WGET|CURL) ) {
      return 404;
  }

  location ~ /\.ht {
    deny  all;
  }

  location ~ \.(rb|php|asp|aspx|dwt|sql|psd|bak|ini|log|md|\w+\~)$ {
    deny  all;
  }

  location ~* \.(?:ico|css|js|gif|jpe?g|png|otf|ttf)$ {
    expires 1h;
  }

  passenger_enabled                 on;
  passenger_friendly_error_pages    off;
  rails_env                         production;
  client_max_body_size              10m;

  error_page 500 502 503 504 /50x.html;

  location = /50x.html {
      root html;
  }
}
' | sudo tee $NGINX_SITES_CONF_PATH/rails.example > /dev/null
}

load_toolkit_setting