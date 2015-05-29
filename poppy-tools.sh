#! /bin/bash

command_name=$1

if [ -z "$command_name" ];
 then
  echo "please try 'poppy-tools help' command";
  exit
fi

shift
bash /home/poppy/dev/poppy-tools/poppy-tools-$command_name.sh $@ || echo "please try 'poppy-tools help' command"
