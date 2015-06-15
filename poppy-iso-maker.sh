#! /bin/bash


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

# Most of the work is actually done by the spindle script
# https://github.com/pierre-rouanet/spindle
# Forked form asb
if [ $POPPY_BOARD = "rpi" ]; then
  old_dir=$(pwd)

  wget "https://github.com/pierre-rouanet/spindle/tarball/master" -O /tmp/spindle.tar.gz
  cd /tmp

  tar -xvf spindle.tar.gz
  rm -rf spindle
  mv pierre-rouanet-spindle* spindle

  cd spindle

  MY_SPINDLE=my_spindle_chroot
  rm -rf $MY_SPINDLE

  set -ex
  sudo ./setup_spindle_environment $MY_SPINDLE
  sudo modprobe nbd max_part=16

  schroot -c spindle sudo ./downgrade_qemu
  
  ./wheezy-stage0
  ./wheezy-stage1
  ./wheezy-stage2
  ./wheezy-stage3
  ./wheezy-stage4-lxde
  ./wheezy-stage5-poppy

  ./helper export_image_for_release out/stage4-lxde.qed stage4-poppy.img

  today=`date +%Y%m%d`
  deb_release="wheezy"

  mv stage4-poppy.img $old_dir/poppy_raspbian_${deb_release}_${today}.img
  cd $old_dir
fi
