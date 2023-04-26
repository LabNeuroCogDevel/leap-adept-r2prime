#!/usr/bin/env bash
#
# run r2p pipeline
#
# 20230426WF - init
#

R2P=/opt/ni_tools/r2prime-prisma

03_r2prime_main() {

  [ "$#" -eq 0 ] && echo "USAGE: $0 [all | path/r2prime]" && exit 1
  [[ "$1" == "all" ]] &&
     indirs=(../data/r2prime/ADEPT*/ses*) ||
     indirs=("$@")
  
  for d in "${indirs[@]}"; do
     /opt/ni_tools/r2prime-prisma/r2prime "$d" &
     waitforjobs -j 10
  done
  wait
}

# if not sourced (testing), run as command
eval "$(iffmain "03_r2prime_main")"

####
# testing with bats. use like
#   bats ./03_r2prime.bash --verbose-run
####
03_r2prime_main_test() { #@test
   run 03_r2prime_main
   [[ $output =~ ".*" ]]
}


