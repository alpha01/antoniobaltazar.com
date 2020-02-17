#!/bin/bash

mkdir ../tests || true

sed -i "s/##TAG##/${BUILD_NUMBER}/g" test-docker-compose.yml
