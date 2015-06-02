#!/usr/bin/env bash

sed -i /PYTHON_VERSION/d $HOME/.bashrc
echo "export PYTHON_VERSION=2.7.10" >> $HOME/.bash_profile
export PYTHON_VERSION=2.7.10

if [ ! -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
  pyenv install -s $PYTHON_VERSION
  pyenv global $PYTHON_VERSION
fi
