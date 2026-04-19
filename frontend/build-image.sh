#!/bin/bash

set -x

docker build -t flutter-web .
docker run -d -p 1200:80 --name flutter flutter-web

# echo $(ip a)