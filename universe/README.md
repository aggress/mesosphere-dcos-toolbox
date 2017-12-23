# mesosphere-dcos-universe-builder

- Simplifies the building of a DC/OS Local Universe
- Accepts an inventory file `local-universe.txt` setting DC/OS version and packages required
- Outputs the compressed Local Universe to a bind mount, ready for pushing to DC/OS

## Prerequisites

- Docker Daemon
- `local-universe.txt` populated with the correct DC/OS version and the list of packages you want to build. You can easily browse the catalog and select the specific versions outside of DC/OS on the [Service Catalog](http://universe.dcos.io/?_ga=2.223726171.1524782797.1514003718-1970164828.1513598594#/packages).

Here's an example:

```
DCOS_VER=1.10
PACKAGES="cassandra:1.0.25-3.0.10,marathon:1.4.2"
```

## Usage

1. Clone this repository to your local machine git@github.com:aggress/mesosphere-dcos-toolbox.git .
1. Start the Docker daemon on your local machine
1. Make sure you have the `local-universe.txt` inventory in your pwd
1. Pull down and run the universe-builder Docker image. Note that rather than running Docker in Docker (dind) this uses a local Docker cli which then talks to the Docker daemon on your local machine, communicating out via the sock file. On macOS and Linux this should work out of the box, on Windows, you may need to change this path.
```
docker run --name=builder -v /var/run/docker.sock:/var/run/docker.sock \
-v /tmp/dcos-local-universe:/tmp/build --env-file=local_universe.txt \
aggress/dcos-local-universe-builder:latest
```
4. Watch the build fly by - depending on the number of packages and resources you've allocated the Docker daemon this can be ~5 minutes
5. `/tmp/dcos-local-universe` on your local machine will have the tar gzip of the Local Universe and the two systemd files. Again on Windows you may want to change this to a different path.
6. Now either follow the instructions for [publishing](https://docs.mesosphere.com/1.10/administering-clusters/deploying-a-local-dcos-universe/) to your DC/OS cluster, or use the [Ansible playbook](https://github.com/aggress/mesosphere-dcos-toolbox/tree/master/ansible) to deploy for you

## Troubleshooting

If Docker complains of an existing container called `builder`, remove it with `docker rm -f /builder`

To run the build manually, get an interative session on the container
```
docker run -it --name=builder -v /var/run/docker.sock:/var/run/docker.sock \
-v ~/dcos-local-universe:/tmp/build --env-file=local_universe.txt \
aggress/dcos-local-universe-builder:latest /bin/bash
```

If you're on Windows, I haven't got round to testing on it yet.