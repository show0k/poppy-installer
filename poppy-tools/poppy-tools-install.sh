#! /bin/bash

sudo apt-get install -y subversion

echo -e "\e[33mDownload sources\e[0m"
svn checkout https://github.com/poppy-project/poppy-installer/trunk/poppy-tools /home/poppy/dev/poppy-tools

bash /home/poppy/dev/poppy-tools/poppy-tools-update.sh

# check env var value
if grep -Fxq "$1" /home/poppy/dev/poppy-tools/poppy-boards
then
    # code if found
    sed -i / Poppy environement variables:/d /home/poppy/.bashrc
    echo "# Poppy environement variables:"
    sed -i /POPPY_BOARD/d /home/poppy/.bashrc
    echo "export POPPY_BOARD=$1" >> /home/poppy/.bashrc
    export POPPY_BOARD=$1

else
    # code if not found
    echo -e "${RED}Unknown poppy-board${NC}"
    print_man
    exit 0
fi


if grep -Fxq "$2" /home/poppy/dev/poppy-tools/poppy-creatures
then
    # code if found
    sed -i /POPPY_CREATURE/d /home/poppy/.bashrc
    echo "export POPPY_CREATURE=$2" >> /home/poppy/.bashrc
    export POPPY_CREATURE=$2

else
    # code if not found
    echo -e "${RED}Unknown poppy-creature${NC}"
    print_man
    exit 0
fi
bash /home/poppy/dev/poppy-tools/poppy-tools-update.sh

function print_man {
               echo "poppy-tools install [board] [creature]."
               echo "Supported boards list :"
               cat /home/poppy/dev/poppy-tools/poppy-boards
               echo "Supported creatures list :"
               cat /home/poppy/dev/poppy-tools/poppy-creatures
           }
