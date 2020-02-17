#!/bin/bash

mkdir ../tests || true

sed -i "s/##TAG##/${env.BUILD_NUMBER}/g" test-docker-compose.yml
sed -i "s/##RANDOM##/${TEST_PORT}/g" test-docker-compose.yml

