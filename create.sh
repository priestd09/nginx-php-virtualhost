#!/bin/bash

NGINX_AVAILABLE='/etc/nginx/sites-available'
NGINX_ENABLED='/etc/nginx/sites-enabled'
DOMAIN=$1
NGINX_CONFIG=$NGINX_AVAILABLE/$DOMAIN
FPM_DIR='/etc/php5/fpm/pool.d'
FPM_CONFIG=$FPM_DIR/$DOMAIN.conf
SFTP_GROUP='sftpuser'

# check domain exist
if [ -e $NGINX_CONFIG/$DOMAIN.conf ]; then
	echo "Domain already exists"
	exit 1   
fi

# create user
while [[ -z "$USERNAME" ]]
do
  read -s -p "Please specify the username for this site: " $USERNAME
done

HOMEDIR="/home/$USERNAME"
adduser $USERNAME

# root dir
echo "Enter the new web root dir [/home/$USERNAME/web/public]: "
read ROOTDIR

if [ -z "ROOTDIR" ]
    ROOTDIR=$HOMEDIR/web/public
fi

cp ./templates/nginx.conf $NGINX_CONFIG

sed -i '' "s|{{ROOTDIR}}|$ROOTDIR|g" $NGINX_CONFIG
sed -i '' "s|{{DOMAIN}}|$DOMAIN|g" $NGINX_CONFIG
sed -i '' "s|{{USERNAME}}|$USERNAME|g" $NGINX_CONFIG

mkdir -p $ROOTDIR
chmod 750 $ROOTDIR
chown $USERNAME:$USERNAME $HOMDIR -R

echo "Enter FPM max_children [5]: "
read MAX_CHILDREN

if [ -z "MAX_CHILDREN" ]
    MAX_CHILDREN=5
fi

echo "Enter FPM start_servers [2]: "
read START_SERVER

if [ -z "START_SERVER" ]
    START_SERVER=2
fi

echo "Enter FPM min_spare_servers [1]: "
read MIN_SPARE

if [ -z "MIN_SPARE" ]
    MIN_SPARE=1
fi

echo "Enter FPM max_spare_servers [3]: "
read MAX_SPARE

if [ -z "MAX_SPARE" ]
    MAX_SPARE=3
fi

cp ./templates/fpm.conf $FPM_CONFIG

sed -i '' "s|{{USERNAME}}|$USERNAME|g" $FPM_CONFIG
sed -i '' "s|{{MAX_CHILDREN}}|$MAX_CHILDREN|g" $FPM_CONFIG
sed -i '' "s|{{START_SERVER}}|$START_SERVER|g" $FPM_CONFIG
sed -i '' "s|{{MIN_SPARE}}|$MIN_SPARE|g" $FPM_CONFIG
sed -i '' "s|{{MAX_SPARE}}|$MAX_SPARE|g" $FPM_CONFIG

usermod -aG $USERNAME $SFTP_GROUP
chown root:$USERNAME $HOMEDIR

systemctl reload nginx
systemctl reload php-fpm