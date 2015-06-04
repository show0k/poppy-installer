#!/usr/bin/env bash

if [ "$POPPY_BOARD" == "rpi" ]; then
  pip install picamera[array] -U
fi
