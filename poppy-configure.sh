#! /bin/bash

# This bash script configure your poppy dedicated linux

arch="$(uname -m)"
if [[ $arch != arm* ]]
then
        echo -e "\e[31mWARNING\e[0m : \e[33mThis script change some system setting, you should NOT run it in your desk computer.\e[0m"
        exit 0
fi

if [ `whoami` != "root" ];
then
    echo "You must run the app as root:"
    echo "sudo bash $0"
    exit 0
fi

# Change hostname to poppy
apt-get install -y avahi-daemon passwd libnss-mdns
echo -e "\e[33mDefault Hostname change to \e[4mpoppy\e[0m."
echo 'poppy' > /etc/hostname
echo '127.0.0.1     poppy' >> /etc/hosts
service avahi-daemon restart

# Create the poppy session
echo -e "\e[33mCreate a new user \e[4mpoppy\e[0m\e[33m with the default password \e[4mpoppy\e[0m."

POPPY_GROUPS="adm,dialout,sudo,audio,video,plugdev,netdev"

if [[ $1 == "odroid" ]];
then
  POPPY_GROUPS=$POPPY_GROUPS,fax,cdrom,floppy,tape,dip,lpadmin,fuse
fi
if [[ $1 == "rpi" ]];
then
  POPPY_GROUPS=$POPPY_GROUPS,cdrom,games,users
fi

useradd -m -s /bin/bash -G $POPPY_GROUPS poppy

echo poppy:poppy | chpasswd
export HOME=/home/poppy
su - poppy -c "wget -P  /home/poppy/ https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-logo"
sed -i /poppy-logo/d /home/poppy/.bashrc
echo cat /home/poppy/poppy-logo >> /home/poppy/.bashrc

# Allow poppy to use sudo without password
chmod +w /etc/sudoers
echo "poppy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -w /etc/sudoers
usermod --pass='*' root # don't need root password anymore

# Download and run poppy-tools install
su - poppy -c "wget -P /home/poppy/ https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-tools.sh"
mv /home/poppy/poppy-tools.sh /usr/local/bin/poppy-tools
chmod +x /usr/local/bin/poppy-tools
su - poppy -c "mkdir /home/poppy/dev /home/poppy/dev/poppy-tools"

su - poppy -c "poppy-tools install $*"
