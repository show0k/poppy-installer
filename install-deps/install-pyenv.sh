#!/usr/bin/env bash

if [ ! -d "$HOME/.pyenv" ]; then
  sudo apt-get install -y curl git
  sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm
  sudo apt-get install -y libfreetype6-dev libpng++-dev

  curl -L https://raw.githubusercontent.com/pierre-rouanet/pyenv-installer/master/bin/pyenv-installer | bash

  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  echo "
export PATH=\"\$HOME/.pyenv/bin:\$PATH\"
eval \"\$(pyenv init -)\"
eval \"\$(pyenv virtualenv-init -)\"" >> $HOME/.poppy_profile
fi
