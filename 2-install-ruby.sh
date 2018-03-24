#!/bin/bash

RUBY_VERSION=2.5.0

function run_script_install_ruby()
{
  echo "Clone rbenv repo" | shell_log
  clone_rbenv_repo

  echo "Init rbenv to deploy account" | shell_log
  init_rbenv_to_deploy_account

  echo "Install ruby $RUBY_VERSION " | shell_log
  install_ruby
}

function clone_rbenv_repo()
{
  rm -rfv  ~/.rbenv
  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
}

function check_rbenv_dir()
{
  if [ -d ~/.rbenv ] && [ -d ~/.rbenv/plugins/ruby-build ]
  then
    echo "ok"
  fi
}

function init_rbenv_to_deploy_account()
{
  local rbenv_is_setup=`check_rbenv_dir`

  if [ "$rbenv_is_setup" == 'ok' ]
  then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"

    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

    echo "gem: --no-ri --no-rdoc --verbose" > ~/.gemrc

    echo "<rbenv> completed" | shell_log
  else
    echo "<rbenv> is not found" | shell_error
  fi
}

function install_ruby()
{
  echo "Start compile ruby $RUBY_VERSION" | shell_log
  rm -rfv ~/.rbenv/versions/$RUBY_VERSION > /dev/null
  rbenv install $RUBY_VERSION --verbose 

  if [ -d ~/.rbenv/versions/$RUBY_VERSION ]
  then
    echo "Remove compiler files" | shell_log
    sudo rm -rfv /tmp/* > /dev/null

    echo "Install ruby $RUBY_VERSION" | shell_log
    rbenv global $RUBY_VERSION
    rbenv rehash

    if [[ "`ruby -v`" =~ "ruby $RUBY_VERSION" ]]
    then
      echo "Install ruby $RUBY_VERSION completed" | shell_log
    else
      echo "Install ruby failed" | shell_error
    fi
  else
    echo "Install ruby failed" | shell_error
  fi
}

run_script_install_ruby