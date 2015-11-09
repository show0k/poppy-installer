#!/bin/bash

echo -e "\e[33mInstalling poppy web apps"

# Check if user is not root (env is not shared between users)
if [[ $EUID -eq 0 ]]; then
    echo -e "\x1b[1m\x1b[31mScript MUST NOT be started at root."
    echo -e "ENV variables are not shared between users"
    echo -e "QUITTING NOW... \e[0m"

    exit 1
fi

## Check all environment variables
if [ -z ${POPPY_CREATURE+x} ]; then 
    POPPY_CREATURE=poppy-torso
    echo -e "\x1b[1m\x1b[31mPOPPY_CREATURE was not set. Automaticaly set to $POPPY_CREATURE \e[0m "
else
    echo "POPPY_CREATURE=$POPPY_CREATURE"
fi

if [ -z ${POPPY_WWW+x} ]; then 
    POPPY_WWW=/var/www/poppy_webapps
    echo -e "export POPPY_WWW=$POPPY_WWW" >> $HOME/.profile
    echo -e "\e[33mPOPPY_WWW was not set. Automaticaly set to $POPPY_WWW \e[0m"
else
    echo "POPPY_WWW=$POPPY_WWW"
fi

if [ -z ${POPPY_USER+x} ]; then 
    POPPY_USER=poppy
    echo -e "export POPPY_USER=$POPPY_USER" >> $HOME/.profile
    echo -e "\e[33mPOPPY_USER was not set. Automaticaly set to $POPPY_USER \e[0m"
else
    echo "POPPY_USER=$POPPY_USER"
fi

if [ "$(id -u $POPPY_USER > /dev/null 2>&1; echo $?)" -eq 1 ]; then
    echo -e "\x1b[1m\x1b[31m$POPPY_USER IS NOT A VALID USER. EXITING... \e[0m"
    exit 1
fi

if [ -z ${POPPY_ROOT+x} ]; then 
    POPPY_ROOT="/home/$POPPY_USER/dev"
    echo -e "export POPPY_ROOT=$POPPY_ROOT" >> $HOME/.profile
    echo -e "\x1b[1m\x1b[31mPOPPY_ROOT was not set. Automaticaly set to $POPPY_ROOT \e[0m"
else
    echo "POPPY_ROOT=$POPPY_ROOT"
fi

if [ -z ${POPPY_SERVICE_PATH+x} ]; then 
    POPPY_SERVICE_PATH="/home/poppy/.pyenv/shims/poppy-services"
    echo -e "export POPPY_SERVICE_PATH=$POPPY_SERVICE_PATH" >> $HOME/.profile
    echo -e "\x1b[1m\x1b[31mPOPPY_ROOT was not set. Automaticaly set to $POPPY_ROOT \e[0m"
else
    echo "POPPY_SERVICE_PATH=$POPPY_SERVICE_PATH"
fi

################################################################################
## Install Wifi php web app
################################################################################
# Change owner of /var/www
echo -e "\e[33mChange owner of $(dirname "$POPPY_WWW") to $POPPY_USER\e[0m"
sudo chown -R $POPPY_USER:$POPPY_USER "$(dirname "$POPPY_WWW")"


# Sudo configuration for the websudoer app
line="$POPPY_USER ALL=(ALL) NOPASSWD: /usr/local/robot/websudoer/websudoer.sh"
if ! sudo grep -q "$line" /etc/sudoers; then
    echo -e "\e[33mChange sudo file configuration for root access: $line\e[0m"
    echo -e "$line" | sudo tee -a  /etc/sudoers
fi

sudo apt-get -y install apache2 php5 libapache2-mod-php5 network-manager avahi-daemon libnss-mdns subversion

# Apache configuration
APACHE_CONF="
        <VirtualHost *:80>\n
            ServerAdmin webmaster@localhost\n
            DocumentRoot $POPPY_WWW\n
            ErrorLog ${APACHE_LOG_DIR}/error.log\n
            CustomLog ${APACHE_LOG_DIR}/access.log combined\n
            <Directory />\n
                Order deny,allow\n
                Allow from all\n
            </Directory>\n
        </VirtualHost>"

echo -e "\e[33m\nApache server configuration (it will erase your current configuration)  \e[0m"
# Tee is used because echo cannot sudo to a file
echo -e "$APACHE_CONF" | sudo tee /etc/apache2/sites-enabled/000-default.conf
echo -e "$APACHE_CONF" | sudo tee /etc/apache2/sites-enabled/000-default


# Change apache2 user used to execute scripts 
# This security hole is not too serious because poppy is always used in local network or behind a NAT
sudo sed -i.bak "s/www-data/$POPPY_USER/g" /etc/apache2/envvars

if [ ! -d "$POPPY_WWW" ]; then
    sudo mkdir -p $POPPY_WWW
fi

# Download sources
echo -e "\e[33mDownload sources\e[0m"
sudo rm /usr/local/robot/websudoer/websudoer.sh
sudo curl https://raw.githubusercontent.com/MakingBot/webapp/master/websudoer/websudoer.sh --create-dirs -o /usr/local/robot/websudoer/websudoer.sh

sudo chmod +x /usr/local/robot/websudoer/websudoer.sh
svn checkout https://github.com/MakingBot/webapp/trunk/web "$POPPY_WWW/wireless"


# Make $POPPY_USER owner of $POPPY_WWW
echo -e "\e[33mChange apache execution user to $POPPY_USER\e[0m"
sudo chown -R $POPPY_USER:$POPPY_USER $POPPY_WWW

echo -e "\e[33mRestart Apache\e[0m"
sudo service apache2 restart

################################################################################
## Install Snap!
################################################################################
snap_dir=snap
echo -e "\e[33mInstalling Snap! to $POPPY_WWW/$snap_dir\e[0m"
cd $POPPY_WWW
if [ -d "$snap_dir" ]; then 
    # pull remote repo whatever uncommited files
    cd "$snap_dir"
    git fetch origin master
    git reset --hard FETCH_HEAD
    git clean -df
else
    # git clone if it was never done
    git clone https://github.com/poppy-project/Snap--Build-Your-Own-Blocks.git $snap_dir
    cd $snap_dir
fi

# copy basic Snap! blocks in "libraries" directory
cd libraries/
ln -s "$POPPY_ROOT/pypot/pypot/server/snap_projects/pypot-snap-blocks.xml" .
echo -e "pypot-snap-blocks.xml Poppy Blocks" >> LIBRARIES

# copy all Snap! projects examples
cd ../Examples/

#xml_files=$POPPY_ROOT
#path="/pypot/pypot/server/snap_projects/*.xml"
#xml_files+=$path

for project in "$POPPY_ROOT/pypot/pypot/server/snap_projects/*.xml"; do 
    ln -s $project .
    echo -e "add $project to local examples" ;
done
################################################################################
## Install Poppy-monitor
################################################################################
poppy_monitor_dir=$POPPY_WWW/poppy-monitor
echo -e "\e[33mInstalling Poppy-monitor to $poppy_monitor_dir\e[0m"
if [ -d "$poppy_monitor_dir" ]; then
    rm -rf $poppy_monitor_dir
fi
git clone https://github.com/poppy-project/poppy-monitor.git $poppy_monitor_dir

################################################################################
## Install home page
################################################################################
# fix some svn merge failed issue
rm $POPPY_WWW/services.php*

# TODO: change repo URL after pull request
www_url=https://github.com/show0k/poppy-installer/trunk/install-deps/www-files

echo -e "\e[33mInstalling Home page from $www_url to $POPPY_ROOT\e[0m"
svn checkout $www_url $POPPY_WWW

# Change creature name
sed -i "s/poppy-torso/$POPPY_CREATURE/g" $POPPY_WWW/services.php
sed -i "s/poppy-torso/Robot $POPPY_CREATURE/g" $POPPY_WWW/index.html

# Change POPPY_SERVICE_PATH
sed -i "s#POPPY_SERVICE_PATH#$POPPY_SERVICE_PATH#g" $POPPY_WWW/services.php

# Make $POPPY_USER owner of $POPPY_WWW
echo -e "\e[33mChange apache execution user to $POPPY_USER\e[0m"
sudo chown -R $POPPY_USER:$POPPY_USER $POPPY_WWW



