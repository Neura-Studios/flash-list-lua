#!/bin/sh

set -e

./scripts/build-roblox-model.sh
./scripts/build-single-file.sh
./scripts/build-wally-package.sh
