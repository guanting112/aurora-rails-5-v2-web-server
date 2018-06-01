#!/bin/bash

function run_script_install_nginx_and_passenger()
{
  install_phusion_pgp_key
  update_phusion_dpkg
  install_nginx_and_passenger
  setting_nginx_and_passenger_conf
}

function update_phusion_dpkg()
{
  echo "Use Phusion's APT repository " | shell_log
  echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main' | sudo tee /etc/apt/sources.list.d/passenger.list > /dev/null
  sudo chown root: /etc/apt/sources.list.d/passenger.list
  sudo chmod 644 /etc/apt/sources.list.d/passenger.list
  sudo apt -y update
}

function install_nginx_and_passenger()
{
  echo "Install Nginx and passenger" | shell_log

  sudo apt install -y nginx-extras passenger 
}

function install_phusion_pgp_key()
{
  echo "Install phusion pgp key" | shell_log

  sudo apt install -y dirmngr gnupg 
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
  sudo apt install -y apt-transport-https ca-certificates
}

function setting_nginx_and_passenger_conf()
{
  local nginx_is_installed=0
  local passenger_is_installed=0

  [ "`which nginx`" == '/usr/sbin/nginx' ] && nginx_is_installed=1
  [ "`which passenger-status`" == '/usr/sbin/passenger-status' ] && passenger_is_installed=1

  if [ $nginx_is_installed == 1 ] && [ $passenger_is_installed == 1 ]
  then
    echo "Stop nginx service" | shell_log
    sudo service nginx stop

    if [ ! -f /etc/nginx/nginx.conf.example ]; then
      echo "Backup nginx default conf" | shell_log
      sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.example
    fi

    echo "Reset nginx conf" | shell_log

    echo "Reset passenger_root and passenger_ruby path" | shell_log
    echo "Close server tokens" | shell_log
    echo "Gzip setting optimization" | shell_log

    echo "Update" | shell_log
    create_nginx_server_conf

    if [ ! -f /etc/nginx/sites-available/default.example ]; then
      echo "Backup Default Website Conf" | shell_log
      sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.example
    fi

    echo "Reset Website Default Conf" | shell_log
    printf '%s' '
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    server_name localhost;
    return 400;
}
' | sudo tee /etc/nginx/sites-available/default > /dev/null

    if [[ "`sudo nginx -t 2>&1`" =~ "syntax is ok" ]]
    then
      echo "Restart nginx service" | shell_log
      sudo service nginx restart

      echo "Setting Nginx and passenger completed" | shell_log

    else
      echo "An unexpected error has occurred" | shell_error
    fi

  else
    echo "Needs to install nginx or passenger" | shell_error
  fi
}

function create_nginx_server_conf()
{
  printf '%s' '
user www-data;
worker_processes 2;
pid /run/nginx.pid;

events {
  worker_connections 768;
  # multi_accept on;
}

http {

  ##
  # Basic Settings
  ##

  more_clear_headers "Server";
  more_clear_headers "X-Powered-By";
  more_set_headers "Server: Aurora";

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  server_tokens off;

  # server_names_hash_bucket_size 64;
  # server_name_in_redirect off;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  ##
  # Logging Settings
  ##

  access_log /var/log/nginx/access.log combined buffer=512k;
  error_log /var/log/nginx/error.log crit;

  ##
  # Gzip Settings
  ##

  gzip on;
  gzip_disable "msie6";

  # gzip_vary on;
  # gzip_proxied any;
  gzip_comp_level 3;
  gzip_buffers 16 8k;
  # gzip_http_version 1.1;
  gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript image/jpeg image/gif image/png;

  ##
  # nginx-naxsi config
  ##
  # Uncomment it if you installed nginx-naxsi
  ##
  # include /etc/nginx/naxsi_core.rules;

  ##
  # Phusion Passenger config
  ##
  passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
  passenger_ruby [RUBY_ROOT];
  passenger_show_version_in_header off;
  passenger_max_pool_size 6;
  passenger_min_instances 2;
  passenger_max_request_queue_size 500;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}

' | sudo tee /etc/nginx/nginx.conf > /dev/null

  sudo sed -r "s:\[RUBY_ROOT\]:$HOME/.rbenv/shims/ruby:g" -i /etc/nginx/nginx.conf

}

run_script_install_nginx_and_passenger