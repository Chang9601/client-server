#!/bin/bash

############################################################################
##
##     This file is part of Purdue CS 422.
##
##     Purdue CS 422 is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
##
##     Purdue CS 422 is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
##
##     You should have received a copy of the GNU General Public License
##     along with Purdue CS 422. If not, see <https://www.gnu.org/licenses/>.
##
#############################################################################

## SYNOPSIS
##    client-server.sh
##
## DESCRIPTION
##    CS 422 test script for assignment 1.
##    Runs 4 different tests between each possible client/server combination.

# Check correct number of arguments
if [[ $# -ne 1 ]]; then
  printf "USAGE: $0 [server port]\n"
  exit
fi

WORKSPACE=.workspace
numCorrect=0
TESTS_PER_IMPL=5 # REMEBER TO UPDATE THIS IF NUMBER CHANGES!!!
LANGUAGE="python"
PORT=$1
SKIP_MESSAGE="One or both programs missing. Skipping. \n\n"
testNum=1

# Locations of student and instructor files
SRCS_DIR=../srcs
SCC=$SRCS_DIR/client-c # Student C client
SCS=$SRCS_DIR/server-c # Student C server
SPC=$SRCS_DIR/client-python.py # Student python client
SPS=$SRCS_DIR/server-python.py # Student python server

echo $SCC
echo $SPC

# function to compare message files
# $1 = first file, $2 = second file, $3 = print separator (no if 0, yes otherwise),
# $4 = print diff (no if 0, yes otherwise)
function compare {
  if diff -q $1 $2 > /dev/null; then
    printf "\nSUCCESS: Message received matches message sent!\n"
    ((numCorrect++))
  else
    printf "\nFAILURE: Message received doesn't match message sent.\n"
    if [ $4 -ne 0 ]; then
      echo Differences:
      diff $1 $2
    fi
  fi
  if [ $3 -ne 0 ]; then
    printf "________________________________________"
  fi
  printf "\n"
}

# $1 = client, $2 = server, $3 = port, $4 = print separator (no if 0, yes otherwise),
# $5 = print diff (no if 0, yes otherwise)
function test {
  $2 $3 > test_output.txt &
  SERVER_PID=$!
  sleep 0.2
  $1 127.0.0.1 $3 < test_message.txt >/dev/null
  EXIT_STATUS=$?
  sleep 0.2
  kill $SERVER_PID
  wait $SERVER_PID 2> /dev/null
  sleep 0.2
  compare test_message.txt test_output.txt $4 $5
  rm -f test_output.txt
  sleep 0.2
}

#####################################################
# Tests, $1 = client, $2 = server, $3 = port
#####################################################

function all-tests {

  printf "\n$testNum. TEST SHORT MESSAGE\n"
  printf "Go Boilermakers!\n" > test_message.txt
  test "$1" "$2" $3 1 1
  ((testNum++))

  ###############################################################################

  printf "\n$testNum. TEST RANDOM ALPHANUMERIC MESSAGE\n"
  head -c100000 /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' > test_message.txt
  test "$1" "$2" $3 1 0
  ((testNum++))

  ###############################################################################

  printf "\n$testNum. TEST RANDOM BINARY MESSAGE\n"
  head -c100000 /dev/urandom > test_message.txt
  test "$1" "$2" $3 1 0
  ((testNum++))

  ###############################################################################

  printf "\n$testNum. TEST SERVER INFINITE LOOP (multiple sequential clients to same server)\n"
  $2 $3 > test_output.txt &
  SERVER_PID=$!
  sleep 0.2
  printf "Line 1\n" | $1 127.0.0.1 $3 >/dev/null
  sleep 0.1
  printf "Line 2\n" | $1 127.0.0.1 $3 >/dev/null
  sleep 0.1
  printf "Line 3\n" | $1 127.0.0.1 $3 >/dev/null
  sleep 0.1
  kill $SERVER_PID
  wait $SERVER_PID 2> /dev/null
  sleep 0.2
  printf "Line 1\nLine 2\nLine 3\n" > test_message.txt
  compare test_message.txt test_output.txt 1 1
  rm -f test_output.txt
  sleep 0.2
  ((testNum++))
}

function handle_interrupt {
  kill $SERVER_PID 2> /dev/null
  wait $SERVER_PID &> /dev/null
  for i in {0..9}; do
    kill ${CLIENT_PID[$i]} 2> /dev/null
    wait ${CLIENT_PID[$i]} &> /dev/null
  done
  rm -rf $WORKSPACE
  echo ""
  exit 1
}
# Kill server in case of SIGINT so port is correctly freed
trap handle_interrupt SIGINT

####################################################
# RUN TESTS
####################################################

rm -rf $WORKSPACE
mkdir $WORKSPACE
cd $WORKSPACE

printf "================================================================\n"
printf "Testing C client against C server (1/4)                         \n"
printf "================================================================\n"

if [[ -f $SCC && -f $SCS ]]; then
  all-tests $SCC $SCS $PORT
else
  printf "\n$SKIP_MESSAGE"
  ((testNum+=$TESTS_PER_IMPL))
fi

if [[ $LANGUAGE == "python" ]]; then

  printf "================================================================\n"
  printf "Testing Python client against Python server (2/4)               \n"
  printf "================================================================\n"

  if [[ -f $SPC && -f $SPS ]]; then
    all-tests "python $SPC" "python $SPS" $PORT
  else
    printf "\n$SKIP_MESSAGE"
    ((testNum+=$TESTS_PER_IMPL))
  fi

  printf "================================================================\n"
  printf "Testing C client against Python server (3/4)                    \n"
  printf "================================================================\n"

  if [[ -f $SCC && -f $SPS ]]; then
    all-tests $SCC "python $SPS" $PORT
  else
    printf "\n$SKIP_MESSAGE"
    ((testNum+=$TESTS_PER_IMPL))
  fi

  printf "================================================================\n"
  printf "Testing Python client against C server (4/4)                    \n"
  printf "================================================================\n"

  if [[ -f $SPC && -f $SCS ]]; then
    all-tests "python $SPC" $SCS $PORT
  else
    printf "\n$SKIP_MESSAGE"
    ((testNum+=$TESTS_PER_IMPL))
  fi

else
  printf "Language invalid (must be python)\n\n"
  ((testNum+=3*TESTS_PER_IMPL))
fi

rm -rf $WORKSPACE

#####################################################
# Summary Results
#####################################################

printf "================================================================\n\n"
printf "TESTS PASSED: $numCorrect/$((testNum-1))\n"
