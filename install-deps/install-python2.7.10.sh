#!/usr/bin/env bash

sed -i /PYTHON_VERSION/d $HOME/.poppy_profile
echo "export PYTHON_VERSION=2.7.10" >> $HOME/.poppy_profile
export PYTHON_VERSION=2.7.10

if [ ! -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
  pyenv install -s $PYTHON_VERSION
  pyenv global $PYTHON_VERSION
  pyenv rehash
fi
