Docker Ubuntu Systemd
=====================

This Dockerfile can build containers capable to use systemd.

Howto
-----

* adjust files `env.config` and `dpl.config`
* set/export `BUILD_DIST`

* Build the container: `make build`
* Build and publish the container: `make release`
* Publish a container to docker-hub, includes login to the hub: `make publish`
* Run the container: `make run`
* Build an run the container: `make up`
* Stop the running container: `make stop`
* Build the container with differnt config and deploy file: `make cnf=env2.config dpl=env2.deploy build`

* Examples:
```
BUILD_DIST=xenial make build-nc publish-latest
BUILD_DIST=bionic make release

for r in xenial bionic devel; do echo "${r}"; BUILD_DIST="${r}" make release; done
```

License
-------

GNU General Public License v3.0

Author Information
------------------

[@tehtbl](https://github.com/tehtbl)

Sources
-------

This work is based on the great work of many people, e.g.
[robertdebock](https://github.com/robertdebock) and
[geerlingguy](https://github.com/geerlingguy)
