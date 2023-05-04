#!/bin/bash

file1_path=test1.txt
file2_path=test2.txt

d_opt="{\"file1\": \"$(cat $file1_path)\", \"file2\": \"$(cat $file2_path)\"}"

command="curl -H 'Content-Type: application/json' \
  --request POST \
  -d '$d_opt' \
  http://localhost:$1/api"

echo $command

eval $command

d_opt="{\"file1\": \"foo bar\n\", \"file2\": \"foo baz\n\"}"

command="curl -H 'Content-Type: application/json' \
  --request POST \
  -d '$d_opt' \
  http://localhost:$1/api"

echo $command

eval $command
