#! /bin/bash

command_name=$1
shift
bash /home/poppy/dev/poppy-tools/poppy-tools-$command_name.sh $@ || echo "please try 'poppy-tools help' command"
