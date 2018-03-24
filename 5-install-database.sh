#!/bin/bash

function load_setting()
{
  source ~/.stickie
}

function check_setting()
{
  if [ -n $SQL_MAIN_DATABASE_NAME ] &&
     [ -n $SQL_ROOT_PASSWORD ] &&
     [ -n $SQL_MAINTENANCE_USERNAME ] &&
     [ -n $SQL_MAINTENANCE_PASSWORD ] &&
     [ -n $SQL_BACKUP_USERNAME ] &&
     [ -n $SQL_BACKUP_PASSWORD ]
  then
    echo 'OK'
  fi
}

function run_script_install_database()
{
  load_setting

  if [ "`check_setting`" == 'OK' ]
  then
    install_database_server
    init_database_and_setting
    test_database_connection
  else
    echo "Cant Install, script needs <.stickie> file" | shell_error
  fi
}

function install_database_server()
{
  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
  sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.ubuntu-tw.org/mirror/mariadb/repo/10.2/ubuntu xenial main'
  sudo apt -y update

  echo "mariadb-server-10.2 mysql-server/root_password password $SQL_ROOT_PASSWORD" | sudo debconf-set-selections
  echo "mariadb-server-10.2 mysql-server/root_password_again password $SQL_ROOT_PASSWORD" | sudo debconf-set-selections

  echo "Install Database Server (MariaDB Server)" | shell_log
  sudo apt-get install -y mariadb-server | shell_message "apt-get/mariadb-server"

  echo "Install Database Client and Dev file (MariaDB Server)" | shell_log
  sudo apt-get install -y mariadb-client libmariadbclient-dev | shell_message "apt-get/mariadb-client,libmariadbclient-dev"

  if [ -d ~/.rbenv/versions/ ] && [[ "`ruby -v`" =~ "ruby 2" ]]
  then
    echo "Install MySQL2 ruby gem " | shell_log
    gem install mysql2 2>&1 | shell_message "gem/mysql2"
  fi
}

function init_database_and_setting()
{
  echo "Optimize mysql setting" | shell_log
  write_mysql_optimize_config

  echo "Initial Database and setting" | shell_log

  printf '%s' '
-- Create Database --
DROP DATABASE IF EXISTS `[MAIN_DATABASE_NAME]` ;
CREATE DATABASE `[MAIN_DATABASE_NAME]` CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Account "[MAINTENANCE_USERNAME]" password is "[MAINTENANCE_PASSWORD]"
DELETE FROM mysql.db WHERE User = "[MAINTENANCE_USERNAME]" AND Db != "[MAIN_DATABASE_NAME]";

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON [MAIN_DATABASE_NAME].* TO "[MAINTENANCE_USERNAME]"@localhost IDENTIFIED BY "[MAINTENANCE_PASSWORD]" WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;

-- Account "[BACKUP_USERNAME]" password is "[BACKUP_PASSWORD]"
DELETE FROM mysql.db WHERE User = "[BACKUP_USERNAME]" AND Db != "[MAIN_DATABASE_NAME]";

GRANT SELECT, LOCK TABLES ON [MAIN_DATABASE_NAME].* TO "[BACKUP_USERNAME]"@localhost IDENTIFIED BY "[BACKUP_PASSWORD]" WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;

-- Create Test Table --
CREATE TABLE `[MAIN_DATABASE_NAME]`.`test` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- Flush Privileges --
FLUSH PRIVILEGES;
' | sudo tee ~/.reset-sql > /dev/null

  echo "Replace setting" | shell_log

  sudo sed -r "s:\[MAIN_DATABASE_NAME\]:$SQL_MAIN_DATABASE_NAME:g" -i ~/.reset-sql
  sudo sed -r "s:\[MAINTENANCE_USERNAME\]:$SQL_MAINTENANCE_USERNAME:g" -i ~/.reset-sql
  sudo sed -r "s:\[MAINTENANCE_PASSWORD\]:$SQL_MAINTENANCE_PASSWORD:g" -i ~/.reset-sql
  sudo sed -r "s:\[BACKUP_USERNAME\]:$SQL_BACKUP_USERNAME:g" -i ~/.reset-sql
  sudo sed -r "s:\[BACKUP_PASSWORD\]:$SQL_BACKUP_PASSWORD:g" -i ~/.reset-sql

  echo "Import new setting" | shell_log
  mysql -uroot -p$SQL_ROOT_PASSWORD < ~/.reset-sql

  echo "Remove SQL File" | important
  rm -rfv ~/.reset-sql | shell_message rm
}

function test_database_connection()
{
  echo "Test <$SQL_MAINTENANCE_USERNAME> account" | shell_log

  if [[ "`check_database_user $SQL_MAINTENANCE_USERNAME $SQL_MAINTENANCE_PASSWORD`" =~ "OK" ]]; then
    echo "Test connection ok" | shell_message mysql
  else
    echo "Test connection failed" | shell_error
  fi

  echo "Test <$SQL_BACKUP_USERNAME> account" | shell_log

  if [[ "`check_database_user $SQL_BACKUP_USERNAME $SQL_BACKUP_PASSWORD`" =~ "OK" ]]; then
    echo "Test connection ok" | shell_message mysql
  else
    echo "Test connection failed" | shell_error
  fi
}

function check_database_user()
{
  local test_result=`mysql -u$1 --password=$2 --execute 'SELECT 1 FROM '$SQL_MAIN_DATABASE_NAME'.test' 2>&1`

  if [[ $test_result =~ "ERROR" ]]; then
    echo "ERROR"
  else
    echo "OK"
  fi
}

function write_mysql_optimize_config()
{
  printf '%s' "
[client]
default-character-set=utf8

[mysql]
default-character-set=utf8

[mysqld]
collation-server = utf8_unicode_ci
character-set-server = utf8
" | sudo tee /etc/mysql/conf.d/default_character.cnf > /dev/null

  printf '%s' "
[mysqld]
max_connections = 2000
max_user_connections = 0

innodb_buffer_pool_size = 512M
innodb_io_capacity = 800
innodb_io_capacity_max = 2000
innodb_log_block_size = 4096
innodb_log_buffer_size = 128M
innodb_log_file_size = 384M
innodb_autoinc_lock_mode = 1
innodb_file_per_table = 1
innodb_stats_on_metadata = 0
innodb_open_files = 2000
innodb_purge_threads = 1
innodb_lock_wait_timeout = 120

query_cache_size = 128M
query_cache_limit = 4M
query_cache_type = 0
key_buffer = 32M
sort_buffer_size = 32M
" | sudo tee /etc/mysql/conf.d/mysql_optimize.cnf > /dev/null

  sudo service mysql restart
}

run_script_install_database