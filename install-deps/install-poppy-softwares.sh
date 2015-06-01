#! /bin/bash

for repo in pypot poppy-creature $POPPY_CREATURE
do
  cd $POPPY_ROOT

  if [ ! -z "$use_stable_release" ]; then
    pip install $repo
  else
    git clone https://github.com/poppy-project/$repo.git

    cd $repo
    if [[ $repo == poppy-* ]]; then
      cd software
    fi

    python setup.py develop

  fi
fi
