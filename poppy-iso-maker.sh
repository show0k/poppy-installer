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
  schroot -c spindle ./wheezy-stage0
  schroot -c spindle ./wheezy-stage1
  schroot -c spindle ./wheezy-stage2
  schroot -c spindle ./wheezy-stage3
  schroot -c spindle ./wheezy-stage4-lxde

  wget https://raw.githubusercontent.com/poppy-project/poppy-installer/master/poppy-configure.sh
  chmod +x poppy-configure.sh
  schroot -c spindle ./poppy-configure.sh $POPPY_BOARD $POPPY_CREATURE

  schroot -c spindle ./helper export_image_for_release out/stage4-lxde.qed stage4-poppy.img

  today=`date +%Y%m%d`
  deb_release="wheezy"

  mv stage4-poppy.img $old_dir/poppy_raspbian_${deb_release}_${today}.img
  cd $old_dir
fi
