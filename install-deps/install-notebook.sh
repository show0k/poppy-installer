#!/usr/bin/env bash

mkdir $HOME/notebooks

sudo sed -i.bkp "/^exit/i #added lines\nsu poppy <<'EOF'\nipython notebook --ip 0.0.0.0 --no-browser --no-mathjax /home/poppy/notebooks &\nEOF\n" /etc/rc.local
