#!/bin/bash

#进入monitor mode
set -m

current_path=$(
    cd $(dirname $0)
    pwd
)

cd "$current_path/../" || exit 1

git clone https://e.coding.net/licat/chatonline/im.git im
git clone https://e.coding.net/licat/chatonline/server.git server
git clone https://e.coding.net/licat/chatonline/admin.git admin
git clone https://e.coding.net/licat/chatonline/web.git web
git clone https://e.coding.net/licat/chatonline/aos.git aos
git clone https://e.coding.net/licat/chatonline/ios.git ios

if [ ! -f "go.work" ];then
    touch "go.work"
fi
