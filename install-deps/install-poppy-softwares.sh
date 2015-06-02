#!/usr/bin/env bash

for repo in pypot poppy-creature $POPPY_CREATURE
do
  cd $POPPY_ROOT

  if [ ! -z "$use_stable_release" ]; then
    pip install $repo -U
  else
    if [ ! -d "$repo" ]; then
      git clone https://github.com/poppy-project/$repo.git
    fi

    cd $repo
    git pull

    if [[ $repo == poppy-* ]]; then
      cd software
    fi

    python setup.py develop

  fi
done
