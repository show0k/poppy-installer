#!/usr/bin/env bash

sudo apt-get install -y python-numpy python-scipy python-matplotlib

wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
rm get-pip.py

sudo apt-get install libzmq-dev

if hash pip 2>/dev/null; then
  sudo pip install pip -U
else
  wget https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  rm get-pip.py
fi
