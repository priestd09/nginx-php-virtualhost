#!/bin/bash

NGINX_AVAILABLE='/etc/nginx/sites-available'
NGINX_ENABLED='/etc/nginx/sites-enabled'
DOMAIN=$1
NGINX_CONFIG="$NGINX_AVAILABLE/$DOMAIN"
FPM_DIR='/etc/php5/fpm/pool.d'
FPM_CONFIG="$FPM_DIR/$DOMAIN.conf"
SFTP_GROUP='sftpuser'

# check domain exist
if [ -e $NGINX_CONFIG ]; then
	echo "Domain already exists"
	exit 1   
fi

# create user
while [[ -z "$USERNAME" ]]
do
  read -p "Please specify the username for this site: " USERNAME
done

HOMEDIR="/home/$USERNAME"
adduser $USERNAME

# root dir
read -p "Enter the new web root dir [/home/$USERNAME/web/public]: " ROOTDIR

if [[ -z "$ROOTDIR" ]]; then
    ROOTDIR="$HOMEDIR/web/public"
fi

cp ./templates/nginx.conf $NGINX_CONFIG

sed -i'' "s|{{ROOTDIR}}|$ROOTDIR|g" $NGINX_CONFIG
sed -i'' "s|{{DOMAIN}}|$DOMAIN|g" $NGINX_CONFIG
sed -i'' "s|{{USERNAME}}|$USERNAME|g" $NGINX_CONFIG

mkdir -p $ROOTDIR
chmod 750 $ROOTDIR
chown $USERNAME:$USERNAME $HOMEDIR -R

read -p "Enter FPM max_children [5]: " MAX_CHILDREN

if [ -z "$MAX_CHILDREN" ]; then
    MAX_CHILDREN=5
fi

read -p "Enter FPM start_servers [2]: " START_SERVER

if [ -z "$START_SERVER" ]; then
    START_SERVER=2
fi

read -p "Enter FPM min_spare_servers [1]: " MIN_SPARE

if [ -z "$MIN_SPARE" ]; then
    MIN_SPARE=1
fi

read -p "Enter FPM max_spare_servers [3]: " MAX_SPARE

if [ -z "$MAX_SPARE" ]; then
    MAX_SPARE=3
fi

cp ./templates/fpm.conf $FPM_CONFIG

sed -i'' "s|{{USERNAME}}|$USERNAME|g" $FPM_CONFIG
sed -i'' "s|{{MAX_CHILDREN}}|$MAX_CHILDREN|g" $FPM_CONFIG
sed -i'' "s|{{START_SERVER}}|$START_SERVER|g" $FPM_CONFIG
sed -i'' "s|{{MIN_SPARE}}|$MIN_SPARE|g" $FPM_CONFIG
sed -i'' "s|{{MAX_SPARE}}|$MAX_SPARE|g" $FPM_CONFIG

usermod -aG $SFTP_GROUP $USERNAME
chown root:$USERNAME $HOMEDIR

systemctl reload nginx
systemctl reload php5-fpm