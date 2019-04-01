#!/usr/bin/env bash

DATE=$(date +"%y-%m-%d")
docker build -t issmirnov/dcind:$DATE .
docker push issmirnov/dcind:$DATE
