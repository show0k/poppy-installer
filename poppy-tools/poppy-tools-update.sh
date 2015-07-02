#! /bin/bash

wget https://raw.githubusercontent.com/poppy-project/poppy-installer/master/conf/$POPPY_BOARD/$POPPY_CREATURE/install.conf -O /tmp/install-poppy.conf

while IFS=" " read name file_link
do
   echo -e "\e[33m$name instalation: \e[0m"
   curl -L $file_link | bash

done < /tmp/install-poppy.conf
