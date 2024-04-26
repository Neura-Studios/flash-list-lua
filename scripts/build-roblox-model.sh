#!/bin/sh

set -e

build_with_darklua_config () {
    DARKLUA_CONFIG=$1
    OUTPUT=build/$2

    rm -rf roblox

    mkdir -p roblox

    cp -r src roblox/
    ./scripts/remove-tests.sh roblox

    rojo sourcemap model.project.json -o sourcemap.json

    darklua process --config $DARKLUA_CONFIG node_modules roblox/node_modules

    cp $DARKLUA_CONFIG roblox/
    cp sourcemap.json roblox/

    darklua process --config roblox/$DARKLUA_CONFIG roblox/src roblox/src

    ./scripts/remove-tests.sh roblox

    cp model.project.json roblox/

    mkdir -p build
    mkdir -p $(dirname $OUTPUT)

    rojo build roblox/model.project.json -o $OUTPUT
}

build_with_darklua_config .darklua.json flash-list.rbxm
build_with_darklua_config .darklua-dev.json debug/flash-list.rbxm
