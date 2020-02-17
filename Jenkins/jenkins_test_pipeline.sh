#!/bin/bash

mkdir ../tests || true

sed -i "s/##TAG##/${BUILD_NUMBER}/g" test-docker-compose.yml
sed -i "s/##RANDOM##/${TEST_PORT}/g" test-docker-compose.yml

