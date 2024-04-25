#!/bin/sh

set -e

# Default path of Roblox Studio on Mac
robloxPath="/Applications/RobloxStudio.app/Contents/MacOS"

createClientSettingsFile() {
    if [ ! -d "$robloxPath/ClientSettings" ]; then
        mkdir -p "$robloxPath/ClientSettings"
    fi

    if [ ! -f "$robloxPath/ClientSettings/ClientAppSettings.json" ]; then
        printf "{}" > "$robloxPath/ClientSettings/ClientAppSettings.json"
    fi

    # Only add if it isn't already there
    if grep -q "FFlagEnableLoadModule" "$robloxPath/ClientSettings/ClientAppSettings.json"; then
        echo "LoadModule is already enabled"
        return
    fi

    sed -i '' 's/}$/\n\t"FFlagEnableLoadModule": true\n}/' "$robloxPath/ClientSettings/ClientAppSettings.json"
}

createClientSettingsFile
