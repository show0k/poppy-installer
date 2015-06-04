#!/usr/bin/env bash

VISP_VERSION=2.10.0
VISP=ViSP-$VISP_VERSION


if [ ! -d "$POPPY_ROOT/$VISP" ]; then
  sudo apt-get install -y libboost-python-dev
  sudo apt-get install -y libzbar-dev

  cd $POPPY_ROOT

  wget http://gforge.inria.fr/frs/download.php/latestfile/475/$VISP.tar.gz
  tar xvfz $VISP.tar.gz

  cd $VISP/
  mkdir build
  cd build

  cmake .. -DBUILD_DEMOS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DBUILD_TUTORIALS=OFF

  make
  sudo make install

  cd $POPPY_ROOT
  git clone https://github.com/pierre-rouanet/pyvisp.git
  cd pyvisp
  mkdir build
  cd build

  cmake ..
  make
  sudo make install

  sed -i $LD_LIBRARY_PATH:/usr/local/lib/arm-linux-gnueabihf/d $HOME/.bashrc
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/arm-linux-gnueabihf/
  echo "
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/arm-linux-gnueabihf/
  " >> $HOME/.bashrc

  cd $HOME
  python -c "import visp.tracker" && echo "Installation of VISP Ok!"
fi
