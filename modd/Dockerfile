FROM golang:alpine AS builder

#搭建开发环境
LABEL stage=gobuilder

ENV CGO_ENABLED 0
ENV GOPROXY https://goproxy.cn,direct
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk update --no-cache && apk add --no-cache tzdata bash git
ENV TZ Asia/Shanghai

WORKDIR /app

# modd热编译工具
RUN go install github.com/cortesi/modd/cmd/modd@latest

# ENTRYPOINT [ "modd", "-f", "/root/modd.conf" ]
