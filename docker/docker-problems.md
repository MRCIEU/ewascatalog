# Bugs and solutions when building the docker container

This is split into the different OSs where problems occurred. When adding new bugs please add the OS version and the docker version. To get the docker version run `docker version`.

## Mac

### OS version

10.15.7 (catalina)

### `docker version`

`
Client: Docker Engine - Community
 Cloud integration: 1.0.9
 Version:           20.10.5
 API version:       1.41
 Go version:        go1.13.15
 Git commit:        55c4c88
 Built:             Tue Mar  2 20:13:00 2021
 OS/Arch:           darwin/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.5
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.13.15
  Git commit:       363e9a8
  Built:            Tue Mar  2 20:15:47 2021
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.4.3
  GitCommit:        269548fa27e0089a8b8278fc4fc781d7f65a939b
 runc:
  Version:          1.0.0-rc92
  GitCommit:        ff819c7e9184c13b7c2607fe6c30ae19403a7aff
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
`

### problems

1. Creating a user account in the container that matches current user within the [`Dockerfile`](docker/Dockerfile)

solved by replacing `$GROUP_ID` with `999` in the [`Dockerfile`](docker/Dockerfile)

2. When starting the website (with `bash catalog start`) failed to load nginx at this stage: `load metadata for docker.io/tutum/nginx:latest`. Error message included: `failed to load cache key: invalid empty config file resolved for docker.io/tutum/nginx`

solved by running `docker pull tutum/nginx` (see https://hub.docker.com/r/tutum/nginx) 

3. There is no `usermod` function on macos - so can't run `sudo usermod -a -G docker [USER]` to add the user to the 'docker' permissions group

didn't matter on one version of macos, but did on another (unsure which). Can add/modify groups by going to `System Preferences > Users & Groups`, clicking the `+` symbol selecting "Group" in the new account drop-down list, creating the group "docker" and adding your username to it.

## Linux

### OS version

`cat /etc/os-release`
NAME="Ubuntu"
VERSION="16.04.2 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.2 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial

### `docker version`

`
Client:
 Version:           18.09.7
 API version:       1.39
 Go version:        go1.10.4
 Git commit:        2d0083d
 Built:             Wed Oct 14 19:42:56 2020
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          18.09.7
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.4
  Git commit:       2d0083d
  Built:            Wed Oct 14 17:25:58 2020
  OS/Arch:          linux/amd64
  Experimental:     false
`


### problems

1. installing correct python version in the container

solved by replacing `from python:3` with `from python:3.8.6-buster`. If just specifying `from python:3` the python version installed in the container may differ depending on where the container is built.
