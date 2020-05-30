#!/bin/sh

if [ -f "./.env" ]; then
	. ./.env
fi

IMAGE_NAME=${IMAGE_NAME:-morkid/openvpn:latest}
SERVER_NAME=${SERVER_NAME:-}
SERVER_PROTOCOL=${SERVER_PROTOCOL:-tcp}

get_server_name () {
	read -p "Server Name/IP: " SERVER_NAME
	[ -z "$SERVER_NAME" ] && get_server_name
}

get_server_name

cd "`dirname $0`"
export OVPN_DATA=$PWD/data/openvpn
mkdir -p $OVPN_DATA/ccd \
	$OVPN_DATA/clients \
	$PWD/data/nginx/conf.d \
	$PWD/data/logs/nginx \
	$PWD/data/logs/openvpn \
	$PWD/data/logs/sshd
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME ovpn_genconfig -u "$SERVER_PROTOCOL://$SERVER_NAME"
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it $IMAGE_NAME ovpn_initpki
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME chown -R $UID:$GROUPS /etc/openvpn
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME cat /docker-compose.yml > docker-compose.example.yml
docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME cat /etc/nginx/conf.d/default.conf > nginx/default.conf
# docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME chown -R 1000:1000 /etc/openvpn

read -p "Create a new client? [y/n]: " CREATE_CLIENT

if [ "$CREATE_CLIENT" = "y" ]; then
  docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $IMAGE_NAME create-client
fi

read -p "Start server now? [y/n]: " START_SERVER

if [ "$START_SERVER" = "y" ]; then
	docker-compose up -d --force-recreate openvpn
fi
