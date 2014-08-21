#!/bin/sh
#
# Test against a ZooKeeper instance running in a Docker container.
#
# The docker container can by run by the docker service on your workstation,
# or on a remote docker service specified with the DOCKER_HOST environment
# variable.

DOCKER_IMAGE=${DOCKER_IMAGE:=jplock/zookeeper}

remote_docker_ip=$(echo "${DOCKER_HOST}" | sed -ne 's/^.*\/\/\([^:\/]*\).*$/\1/p')
zk_ip=${remote_docker_ip:=localhost}

if ! docker images -q ${DOCKER_IMAGE} | grep -q .; then
	echo -n ">>> Pulling Docker image ${DOCKER_IMAGE} for ZooKeeper"
	docker pull ${DOCKER_IMAGE}
	echo
fi

echo -n ">>> Launching ZooKeeper instance in Docker "
container_id="$(docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 ${DOCKER_IMAGE})"
container_short_id="$(echo ${container_id} | cut -c 1-12)"
echo ${container_short_id}

echo
echo ">>> Waiting for ZooKeeper TCP port"
ruby scripts/wait-for-tcp-port.rb ${zk_ip} 2181

echo
echo ">>> Running tests"
ZK_HOST=${zk_ip}:2181 rspec -cfd spec

echo
echo ">>> Killing ZooKeeper instance ${container_short_id}"
docker kill ${container_id} >/dev/null
