#!/bin/bash

#进入monitor mode
set -m

current_path=$(
    cd $(dirname $0)
    pwd
)

root_name="chatonline"
root_path="$current_path/../"
current_path="$root_path"

cd "$current_path" || exit 1

option_sevice=${1:-auto} # "auto"，"all"，"im"，"server", "manager", "web"

is_auto=0
if [ "$option_sevice" = "auto" ]; then
    is_auto=1
fi

# 当等于 all 时，强制更新全部服务
# 当等于 auto 时，自动更新全部服务
# 当等于 指定服务名 时，强制更新指定服务

function git_pull() {
    local project_name=$1

    cd "$root_path/$project_name" || exit 1

    # 获取当前分支
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [ $is_auto -eq 0 ]; then
        if git pull origin $current_branch; then
            return 0
        else
            echo "更新${project_name}仓库失败"
            return 1
        fi
    fi

    # 拉取远程仓库的更新并获取差异
    git remote update
    git_status=$(git status)

    # 判断本地分支是否落后于远程分支
    if [[ $git_status =~ "Your branch is behind" ]]; then
        # 本地分支落后于远程分支，进行拉取更新操作
        if git pull origin $current_branch; then
            return 0
        else
            echo "更新${project_name}仓库失败"
        fi
    else
        # 本地分支已经是最新的，无需操作
        echo "当前${project_name}本地分支已经是最新的，无需更新"
    fi
    return 1
}

function git_update() {
    local project_name=$1
    local origin_url=$2

    cd "$root_path" || exit 1

    if [[ -d $project_name ]]; then
        cd "$root_path/$project_name" || exit 1
        # echo "Git repository '$project_name' already exists, updating..."
        if ! git_pull "$project_name"; then
            return 1
        fi
    else
        # echo "Git repository '$project_name' does not exist, cloning..."
        if ! git clone $origin_url $project_name; then
            return 1
        fi
        cd "$root_path/$project_name" || exit 1
    fi

    echo "已成功更新${project_name}仓库"
    return 0
}

function build_and_cleanup() {
    local image_name=$1
    local project_name=$2

    local image_full_name="$image_name:latest"

    cd "$root_path/$project_name" || exit 1

    # 构建镜像并设置 "latest" 标签
    if ! docker build -t "$image_full_name" "."; then
        return 1
    fi

    echo "已成功编译${image_full_name}镜像"

    # 获取旧版本镜像 ID
    local old_image_ids=$(docker images "$image_name" --format "{{.ID}}\t{{.Tag}}" | awk '$2 != "latest" {print $1}')

    # 删除旧版本镜像
    if [ -n "$old_image_ids" ]; then
        docker rmi $old_image_ids
        echo "Successfully deleted old versions of '$image_name' image."
    else
        echo "No old versions found for '$image_name' image."
    fi

    return 0
}

function update_image() {
    local project_name=$1
    local origin_url=$2
    local image_name=$3

    local image_tag="latest"

    local image_full_name="$image_name:$image_tag"

    cd "$root_path" || exit 1

    if ! git_update "$project_name" "$origin_url"; then
        # echo "未更新${project_name}仓库"
        return 1
    fi

    if ! build_and_cleanup "$image_name" "$project_name"; then
        echo "编译${image_full_name}镜像失败"
        return 1
    fi

    if ! docker push "${image_full_name}"; then
        echo "上传${image_full_name}镜像失败"
        return 1
    fi

    echo -e "已完成对${image_full_name}镜像的更新\n\n"
    return 0
}

function update_im() {
    update_image "im" "https://github.com/WuKongIM/WuKongIM.git" "licat/wukongim"
}

function update_server() {
    update_image "server" "https://e.coding.net/licat/${root_name}/server.git" "licat/${root_name}/server"
}

function update_manager() {
    update_image "admin" "https://e.coding.net/licat/${root_name}/admin.git" "licat/${root_name}/admin"
}

function update_web() {
    update_image "web" "https://e.coding.net/licat/${root_name}/web.git" "licat/${root_name}/web"
}

case $option_sevice in
"im")
    update_im
    ;;
"server")
    update_server
    ;;
"manager")
    update_manager
    ;;
"web")
    update_web
    ;;
*)
    update_im
    update_server
    update_manager
    update_web
    ;;
esac


function clearup_none_image() {
    # 列出所有的镜像，并获取 tag 为 "none" 的镜像的 IMAGE ID
    image_ids=$(docker images | awk '$2 == "none" { print $3 }')

    # 检查是否有 tag 为 "none" 的镜像
    if [[ -z "$image_ids" ]]; then
        echo "没有找到 tag 为 \"none\" 的镜像"
        exit 0
    fi

    # 删除所有 tag 为 "none" 的镜像
    for image_id in $image_ids; do
        docker rmi $image_id
    done

    echo "已成功删除所有 tag 为 \"none\" 的镜像"
}
