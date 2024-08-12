#!/bin/bash

docker run -v ${PWD}/values.yaml:/tmp/in.yaml -i --rm swaggest/json-cli json-cli build-schema /tmp/in.yaml --pretty > values.schema.json
