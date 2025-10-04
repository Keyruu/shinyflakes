#!/bin/bash

docker pull "$1"
docker save -o "${1##*/}".doc "$1"
