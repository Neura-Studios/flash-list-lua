#!/bin/sh

set -e

mkdir -p build
mkdir -p build/debug

rm -f build/flash-list.lua
rm -f build/debug/flash-list.lua

darklua process --config .darklua-bundle.json src/init.lua build/flash-list.lua
darklua process --config .darklua-bundle-dev.json src/init.lua build/debug/flash-list.lua
