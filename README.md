# Service Discovery

Experimental, ZooKeeper-based service registration and location library for Ruby.

## Testing

The tests require a ZooKeeper instance. These test instructions assume you'll;
be testing against a ZooKeeper instance in a Docker container.

### One time Docker setup

```
# Install Docker

sudo apt-get install -y docker-io || sudo yum install -y docker-io

# Grant yourself permission to drive Docker without root

sudo usermod -a -G docker $(whoami)

# Either log out and back in, or hack your group membership

primary_group=$(id -gn)
newgrp docker
newgrp ${primary_group}
```

### One time Ruby setup

```
git clone git@github.com:sheldonh:service_discovery.git
cd service_discovery
bundle
```

### Running the tests

To start a ZooKeeper container, run the tests against it and then shut it down
(note that the first time will be slow, because it downloads the jplock/zookeeper image from the Docker repository):

```
bundle exec scripts/docker_spec.sh
```

To run tests against some other ZooKeeper instance, the lifecycle of which you manage yourself:

```
ZK_HOST=localhost:2181 bundle exec rspec -cfd spec
```

