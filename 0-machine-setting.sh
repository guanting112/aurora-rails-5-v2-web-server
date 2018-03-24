#!/bin/sh

load_setting()
{

  # This script version
  SCRIPT_VERSION="1.0.0-20180324"

  # Host new SSH Port
  HOST_NEW_SSH_PORT="56888"

  # Host Name (ex: AR52-121212-1200)
  HOST_NODE_NAME_PREFIX="AR52"

  # Deploy Account
  DEPLOY_USER_NAME="apps"
  DEPLOY_USER_PASSWORD=`random_text 16` # Dont touch this

  # Application Database Name
  SQL_MAIN_DATABASE_NAME='production_database'

  # SQL Root Password
  SQL_ROOT_PASSWORD=`random_text 16` # Dont touch this

  # Application Database Account
  SQL_MAINTENANCE_USERNAME='application'
  SQL_MAINTENANCE_PASSWORD=`random_text 16` # Dont touch this
  
  # Backup Database Account
  SQL_BACKUP_USERNAME='backup'
  SQL_BACKUP_PASSWORD=`random_text 16` # Dont touch this

  # Git Repo Host and Key
  GIT_REPO_HOST="bitbucket.org"
  GIT_REPO_DEPLOY_PRIVATE_KEY_NAME="id_rsa_for_deploy"

  # SSH Authorized Keys
  SSH_AUTHORIZED_KEYS='

'

  # [GIT] SSH Private Key for Git Repo
  GIT_REPO_DEPLOY_PUBLIC_KEY_DATA='

'

  # [GIT] SSH Public Key for Git Repo
  GIT_REPO_DEPLOY_PRIVATE_KEY_DATA='

'

  SSH_KEY_CONFIG="
Host $GIT_REPO_HOST
  IdentityFile /home/$DEPLOY_USER_NAME/.ssh/$GIT_REPO_DEPLOY_PRIVATE_KEY_NAME
"

}

