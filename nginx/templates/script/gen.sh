#!/bin/bash

#进入monitor mode
set -m
set -e

current_path=$(
    cd $(dirname $0)
    pwd
)

cd $current_path
cd ..

# 注意：macOS中 bash3.2不支持关联数组，需要升级到bash4+，但不建议这样做，因为Apple仍将版本3作为系统外壳提供
# 故采取此方案

# 服务名，服务地址
weblist=(
    "mysql,mysql_manage:80,auth"
    "redis,redis_manage:80,auth"
    "admin,admin:80,"
    "web,web:80,"
    # "imtcp,wukongim:5100" # 不能经过反代
    # "imws,wukongim:5200"  # 不能经过反代
    "imui,wukongim:5300,auth"
    "api,server:8090,"
)

# split 方法的实现
splitstr() {
    web=$1
    mark=$2
    arr=($(echo $web | tr $mark ' '))
    num=${#arr[@]}
    # if [ $num -ne 2 ]; then
    #     echo "split error: ${web}"
    #     exit 1
    # fi
    echo ${arr[@]}
}

#备份当前文件，备份后，当前文件就不存在了
backup() {
    file=$1
    cpfile="backup/${file}.txt"
    if [ -f $cpfile ]; then
        rm -f $cpfile
    fi
    if [ -f $file ]; then
        mv $file $cpfile
    fi
}

#失败以后得恢复文件
recover() {
    file=$1
    if [ -f $file ]; then
        rm -f $file
    fi
    if [ -f $cpfile ]; then
        mv "backup/${file}" $file
    fi
}

#替换文件中的字符串
replace() {
    file=$1
    oldstr=$2
    newstr=$3

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i "" "s/${oldstr}/${newstr}/g" $file
    else
        sed -i "s/${oldstr}/${newstr}/g" $file
    fi

    set +e # 恢复正常操作

    if [ $? -ne 0 ]; then
        recover $file
        echo "Error: Failed to replace string in file: $file"
        echo "Details: file=$file, oldstr=$oldstr, newstr=$newstr"
        exit 1
    fi
}

current_time=$(date "+%Y-%m-%d %H:%M:%S")
# 核心生产文件
generator() {
    server_name=$1
    server_addr=$2
    server_auth=$3
    filename="${server_name}.conf.template"
    backup $filename
    if [ -f $filename ]; then
        rm -f $filename
    fi
    filename="extend/${filename}"
    cp ./script/extend.temp $filename
    # replace $filename "__DOMAIN__" "${DOMAIN}"
    replace $filename "__NAME__" $server_name
    replace $filename "__ADDR__" $server_addr
    replace $filename "__TIME__" $current_time
    if [ "$server_auth" = "auth" ]; then
        # 取消注释，开启auth
        replace $filename "#auth#" ""
    fi
}

# 兼容性有问题，不可用
insert() {
    line=$1
    text=$2
    file=$3
    sed -i "" "${line}a\ $tex3" $file # macos下 sed 命令有问题
    if [ $? -ne 0 ]; then
        sed -i "${line}a\ $text" $file
    fi
}

if [ ! -d "backup" ]; then
    mkdir "backup"
fi

if [ ! -d "extend" ]; then
    mkdir "extend"
fi

# 将逗号作为分隔符
# IFS=',' read -ra parts <<< "$web"
# echo "${parts[5]}"

for web in ${weblist[@]}; do
    IFS=',' read -ra parts <<< "$web"
    name="${parts[0]}"
    addr="${parts[1]}"
    auth="${parts[2]}"
    $(generator ${name} ${addr} ${auth})
done

echo "----------- generator success -----------"
