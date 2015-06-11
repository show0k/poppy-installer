#!/usr/bin/env bash

OPENCV_VERSION=3.0.0


if [ ! -d "$POPPY_ROOT/opencv-$OPENCV_VERSION" ]; then
  sudo apt-get install -y build-essential cmake pkg-config
  sudo apt-get install -y libgtk2.0-dev
  sudo apt-get install -y libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev
  sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
  sudo apt-get install -y libatlas-base-dev gfortran
  sudo apt-get install -y python-dev python-numpy

  cd $POPPY_ROOT

  wget https://github.com/Itseez/opencv/archive/$OPENCV_VERSION.tar.gz
  tar xvfz $OPENCV_VERSION.tar.gz
  rm $OPENCV_VERSION.tar.gz
  cd opencv-$OPENCV_VERSION

  mkdir build
  cd build

  PYTHON_PREFIX=$HOME/.pyenv/versions/$PYTHON_VERSION/

  cmake -D PYTHON_EXECUTABLE=/usr/bin/python -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF ..

  make -j4

  sudo make install

  ln -s /usr/local/lib/python2.7/dist-packages/cv2.so $PYTHON_PREFIX/lib/python2.7/cv2.so
fi
