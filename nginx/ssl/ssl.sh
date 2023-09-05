#!/bin/bash

# 本地调试时才使用，上线后请使用机构颁发的证书

#进入monitor mode
set -m

current_path=$(
    cd $(dirname $0)
    pwd
)

cd "$current_path/" || exit 1

domain="www.chat233.cc"

#------------------ 方法一 -----------------
function gen_ssl_1() {
    #1.生成私钥(输入一个密码:123456)
    openssl genrsa -des3 -out private.key 2048

    #2.生成证书
    #CN
    #GuangDong
    #GuangZhou
    #IBM
    #IBM
    #$domain
    #licat233@gmail.com
    openssl req -new -key private.key -out server.csr

    #3.生成服务器的私钥，去除密钥口令(123456)
    openssl rsa -in private.key -out server.key

    #4.使用私钥为证书请求签名，生成给服务器签署的证书，格式是x509的PEM格式(mac密码)
    sudo openssl x509 -req -in server.csr -out server.crt -signkey server.key -days 3650
}

#-------------------- 方法二 ------------------
function gen_ssl_2() {
    # 生成PKCS12格式的密钥文件
    keytool -genkey -alias $domain -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -storetype PKCS12 -keystore server.p12 -dname CN=$domain,OU=Test,O=pkslow,L=Guangzhou,C=CN -validity 731 -storepass 123456 -keypass 123456

    # 导出pem(certificate)
    openssl pkcs12 -nokeys -in ./server.p12 -out server.pem

    # 导出key
    openssl pkcs12 -nocerts -nodes -in ./server.p12 -out server.key

    # 输入密码: 123456
}

#进入证书存放目录
# if [ ! -d ~/nginx/ssl/$domain/ ]; then
#     mkdir ~/nginx/ssl/$domain/
# fi

# cd ~/nginx/ssl/$domain/ || exit 1

newdir="${domain}_new"

if [ -d "$newdir" ]; then
    rm -rf $newdir
fi

mkdir "$newdir"

cd "$newdir" || exit 1

if ! gen_ssl_2; then
    cd ../
    rm -rf $newdir
    exit 1
fi

cd ../

rm -rf "${domain}"

mv "./${newdir}" "./${domain}"
