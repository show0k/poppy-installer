#! /bin/bash

# Build Raspbian image, largely inspired by:
# https://github.com/andrius/build-raspbian-image/

if [ ${EUID} -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1
fi

wget https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-tools/poppy-boards -O /tmp/poppy-boards
if grep -Fxq "$1" /tmp/poppy-boards
  then
    POPPY_BOARD=$1
  else
    echo -e "${RED}Unknown poppy-board${NC}"
    exit 0
fi

wget https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-tools/poppy-creatures -O /tmp/poppy-creatures
if grep -Fxq "$2" /tmp/poppy-creatures
  then
    POPPY_CREATURE=$2
  else
    echo -e "${RED}Unknown poppy-creature${NC}"
    exit 0
fi

apt-get update
apt-get install -y binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng

deb_mirror="http://mirrordirector.raspbian.org/raspbian"
deb_local_mirror="http://localhost:3142/archive.raspbian.org/raspbian"

if [ "${deb_local_mirror}" == "" ]; then
  deb_local_mirror=${deb_mirror}
fi

bootsize="64M"
deb_release="wheezy"

relative_path=`dirname $0`

# locate path of this script
absolute_path=`cd ${relative_path}; pwd`

# locate path of delivery content
delivery_path=`cd ${absolute_path}/; pwd`

wget https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-configure.sh -O $delivery_path/poppy-configure.sh


# define destination folder where created image file will be stored
buildenv=`cd ${absolute_path}; mkdir -p images; cd images; pwd`
# buildenv="/tmp/rpi"

# cd ${absolute_path}

rootfs="${buildenv}/rootfs"
bootfs="${rootfs}/boot"

today=`date +%Y%m%d`

image=""

if [ "${device}" == "" ]; then
  echo "no block device given, just creating an image"
  mkdir -p ${buildenv}
  image="${buildenv}/poppy_raspbian_${deb_release}_${today}.img"
  dd if=/dev/zero of=${image} bs=1MB count=3800
  device=`losetup -f --show ${image}`
  echo "image ${image} created and mounted as ${device}"
fi

fdisk ${device} << EOF
n
p
1

+${bootsize}
t
c
n
p
2


w
EOF


if [ "${image}" != "" ]; then
  losetup -d ${device}
  device=`kpartx -va ${image} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
  device="/dev/mapper/${device}"
  bootp=${device}p1
  rootp=${device}p2
else
  if ! [ -b ${device}1 ]; then
    bootp=${device}p1
    rootp=${device}p2
    if ! [ -b ${bootp} ]; then
      echo "uh, oh, something went wrong, can't find bootpartition neither as ${device}1 nor as ${device}p1, exiting."
      exit 1
    fi
  else
    bootp=${device}1
    rootp=${device}2
  fi
fi

mkfs.vfat ${bootp}
mkfs.ext4 ${rootp}

mkdir -p ${rootfs}

mount ${rootp} ${rootfs}

mkdir -p ${rootfs}/proc
mkdir -p ${rootfs}/sys
mkdir -p ${rootfs}/dev
mkdir -p ${rootfs}/dev/pts
mkdir -p ${rootfs}/usr/src/delivery

mount -t proc none ${rootfs}/proc
mount -t sysfs none ${rootfs}/sys
mount -o bind /dev ${rootfs}/dev
mount -o bind /dev/pts ${rootfs}/dev/pts
mount -o bind ${delivery_path} ${rootfs}/usr/src/delivery

cd ${rootfs}

debootstrap --foreign --arch armhf ${deb_release} ${rootfs} ${deb_local_mirror}
cp /usr/bin/qemu-arm-static usr/bin/
LANG=C chroot ${rootfs} /debootstrap/debootstrap --second-stage

mount ${bootp} ${bootfs}

echo "deb ${deb_local_mirror} ${deb_release} main contrib non-free rpi
" > etc/apt/sources.list

echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" > boot/cmdline.txt

echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults        0       0
" > etc/fstab

echo "raspberrypi" > etc/hostname

echo "auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
" > etc/network/interfaces

echo "vchiq
snd_bcm2835
" >> etc/modules

echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us

# Default locale for the system environment:
# Choices: None, en_US.UTF-8
locales	locales/default_environment_locale select	en_US.UTF-8
" > debconf.set

echo "deb http://archive.raspberrypi.org/debian wheezy main
" > etc/apt/sources.list.d/raspi.list

echo "#!/bin/bash

wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key -O - | apt-key add -

debconf-set-selections /debconf.set
rm -f /debconf.set
cd /usr/src/delivery
apt-get update
apt-get -y install git-core binutils ca-certificates curl sudo
wget --continue https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update
chmod +x /usr/bin/rpi-update
mkdir -p /lib/modules/3.1.9+
touch /boot/start.elf
rpi-update
apt-get -y install locales console-common ntp openssh-server less vim
# execute install script at mounted external media (delivery contents folder)
cd
echo \"root:raspberry\" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules

apt-get install -y raspi-config

echo -e \"\e[33mStarting to Poppy-ize the Raspbian.\e[0m\"
cd /usr/src/delivery
bash poppy-configure.sh $POPPY_BOARD $POPPY_CREATURE

rm -f third-stage
" > third-stage
chmod +x third-stage
LANG=C chroot ${rootfs} /third-stage

echo "deb ${deb_mirror} ${deb_release} main contrib non-free
" > etc/apt/sources.list

echo "#!/bin/bash
aptitude update
aptitude clean
apt-get clean
rm -f cleanup
" > cleanup
chmod +x cleanup
LANG=C chroot ${rootfs} /cleanup

cd ${rootfs}

sync
sleep 15

# Make sure we're out of the root fs. We won't be able to unmount otherwise, and umount -l will fail silently.
cd

umount -l ${bootp}

umount -l ${rootfs}/usr/src/delivery
umount -l ${rootfs}/dev/pts
umount -l ${rootfs}/dev
umount -l ${rootfs}/sys
umount -l ${rootfs}/proc

umount -l ${rootfs}
umount -l ${rootp}

# Remove device mapper bindings. Avoids running out of loop devices if run repeatedly.
dmsetup remove_all

echo "finishing ${image}"

if [ "${image}" != "" ]; then
  kpartx -d ${image}
  echo "created image ${image}"
fi

echo "done."
