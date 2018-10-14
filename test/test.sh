#!/bin/sh

set -e

NGX_HOME=/usr/local/nginx
NGX_SBIN=$NGX_HOME/sbin/nginx
NGX_CONF=$NGX_HOME/conf/nginx.conf

TEST_HTTP_SERVER=./http_server.py
TEST_HTTP_SERVER2=./http_server2.py
TEST_NGX_CONF=./nginx.conf
TEST_NGX_CONF2=./nginx2.conf


# build nginx
CWD=$(pwd)
cd $(dirname $CWD)
./build
cd $CWD

# start http server
while [ -z "$(netstat -ntlp | grep '127.0.0.1:8080')" ]
do
    echo "starting http server..."
    nohup $TEST_HTTP_SERVER >> /dev/null 2>&1 &
    sleep 2
done

while [ -z "$(netstat -ntlp | grep '127.0.0.1:8081')" ]
do
    echo "starting http server 2..."
    nohup $TEST_HTTP_SERVER2 >> /dev/null 2>&1 &
    sleep 2
done

# copy nginx.conf
cp -f $TEST_NGX_CONF $NGX_CONF

# start nginx
while [ -z "$(netstat -ntlp | grep 'nginx: master')" ]
do
    echo "starting nginx master..."
    $NGX_SBIN
    sleep 2
done
sleep 2

# fetch nginx pid
ngx_pids=$(ps aux | grep -v grep | grep nginx: | awk '{ print $2 }')

count=0

# test lvload
echo "===> test lvload <==="
while true
do
    echo "" # shift

    # test nginx2.conf case
    time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "=> ${time}: ${TEST_NGX_CONF2}"
    cp -f $TEST_NGX_CONF2 $NGX_CONF

    $NGX_SBIN -s lvload
    count=$(($count+1))
    echo "lvload $count"
    pids=$(ps aux | grep -v grep | grep nginx: | awk '{ print $2 }')
    if [ "$pids" != "$ngx_pids" ]; then
        echo "error: expect '$ngx_pids', but is '$pids'"
    fi

    echo "curl -s -H 'Host: bar1.example.com' http://127.0.0.1/bar1"
    resp=$(curl -s -H 'Host: bar1.example.com' http://127.0.0.1/bar1)
    echo "$resp"
    if [ "$resp" != "Hello Nginx2" ]; then
        echo "error: expetc 'Hello Nginx2', but is '$resp'"
    fi

    echo "curl -s -H 'Host: bar2.example.com' http://127.0.0.1/bar2"
    resp=$(curl -s -H 'Host: bar2.example.com' http://127.0.0.1/bar2)
    echo "$resp"
    if [ "$resp" != "Hello Nginx" ]; then
        echo "error: expetc 'Hello Nginx', but is '$resp'"
    fi

    # show memory usage
    if [ -n "$pids" ]; then
        top -p $(echo $pids | sed 's/ /,/g') -n 1
    fi

    sleep 2; # pause

    # test nginx.conf case
    time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "=> ${time}: ${TEST_NGX_CONF}"
    cp -f $TEST_NGX_CONF $NGX_CONF

    $NGX_SBIN -s lvload
    count=$(($count+1))
    echo "lvload $count"
    pids=$(ps aux | grep -v grep | grep nginx: | awk '{ print $2 }')
    if [ "$pids" != "$ngx_pids" ]; then
        echo "error: expect '$ngx_pids', but is '$pids'"
    fi

    echo "curl -s -H 'Host: foo1.example.com' http://127.0.0.1/foo1"
    resp=$(curl -s -H 'Host: foo1.example.com' http://127.0.0.1/foo1)
    echo "$resp"
    if [ "$resp" != "Hello Nginx" ]; then
        echo "error: expetc 'Hello Nginx', but is '$resp'"
    fi

    echo "curl -s -H 'Host: foo2.example.com' http://127.0.0.1/foo2"
    resp=$(curl -s -H 'Host: foo2.example.com' http://127.0.0.1/foo2)
    echo "$resp"
    if [ "$resp" != "Hello Nginx2" ]; then
        echo "error: expetc 'Hello Nginx2', but is '$resp'"
    fi

    # show memory usage
    if [ -n "$pids" ]; then
        top -p $(echo $pids | sed 's/ /,/g') -n 1
    fi

    sleep 2; # pause
done
