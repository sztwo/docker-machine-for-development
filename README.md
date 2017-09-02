# Docker Machine for Development

This repository is a summary of the minimum functions necessary to make a remote server into a development environment using docker-machine.
Although it was made for Machintosh, it works even on Windows and Linux by making a little modification. (It is necessary to prepare the environment where docker and Lsyncd, rsync, Lua work)

[日本語のREADMEはこちら](README_ja.md)

## Overview

Docker Machine for Development provides the minimum configuration required to run Docker for development environments on a remote server.
By introducing docker-compose in the repository to the remote server using docker-machine, it is possible to start up the Docker container using the remote server's abundant resources without using the computing capacity of the local machine, You can do development on.

The main functions are:

- Able to use the VirtualHost name to access various docker containers running on the server.
- Able to set basic authentication ID / password for each VirtualHost.
- Able to make settings that do not use basic authentication (when accessing from a specific IP address).
- The contents modified on the local machine are (almost) delayed on the remote server without delay.
- Of course it is also possible to run Docker on the local machine.

All basic settings are stored in this repository.
You can start using it by forking or cloning the repository and changing the necessary parts.

### HTTP Proxy (based on nginx)
This is an nginx-based reverse proxy server. It supports HTTP and HTTPS access.
In principle, access to the docker container of the remote server takes the form of access via this proxy server (docker container).

This proxy server includes the ability to issue SSH certificates with Let's Encrypt (staging mode is set as default).
Commenting out the environment variable `ACME_CA_URI` will operate in production mode.
The environment variable `LETSENCRYPT_TEST` is prepared to set the staging mode in each docker container.

In addition, can also perform name resolution.
Name resolution by VirtualHost is also valid for other docker containers running on the same server. When you start another docker container, the proxy server detects it and automatically performs name resolution.
To use this feature, the proxy docker server and other docker servers must be on the same virtual network.
You also need to use the environment variable `VIRTUAL_HOST`.

The details of how to set basic authentication for each VirtualHost and how to not use basic authentication when accessing from a specific IP address is explained in the "Advanced Settings" section.

### Lsyncd + rsync
This function is to make the changes made on the local machine immediately to be reflected on the remote server. Lsyncd detects changes below the specified directory, and rsync immediately reflects changes to the remote server.
Which directory to detect and which files to exclude from uploading can be customized with the configuration file described in lua.

The docker container running on the remote server can detect the changed file on the remote server via rsync. So in most cases you can check the file changes simply by reloading the application under development (without restarting the docker container).

Note: If you modified the file that did not detect the change of the file after reading at the docker container startup, you need to restart the container the same way as when developing on the local machine.

## Audience

Docker Machine for Development is provided for those who develop on local machines that do not have sufficient machine power.
However, it is intended for users who can prepare a (remote) server for development.

This includes:
* Developers who can not make Docker work satisfactorily on the local machine because they do not have sufficient machine power.
* Developer who needs to develop various projects simultaneously.
* Projects that need to test and modify simultaneously on multiple smartphones and PCs, using multiple version browsers.
* Projects that need access to development servers from various environments, such as performing remote work.

This is NOT recommended for:
* Operation of production environment. It is not recommended because it has low track record of production environment using Docker.
* A person who has high local machine specifications and does not work collaboratively with others. Please move Docker on local machine.
* Person who is resistant to operating Terminal (black screen). GUI is not prepared.
* Docker beginners. Please get used to running Docker locally first.

In the above case, it would be easier to run Docker on the local machine.

## Usage

It is a premise that [Docker for Mac](https://docs.docker.com/docker-for-mac/) and [Homebrew](https://brew.sh/index.html) are already installed.
In addition, Ubuntu 16.04 is used for the remote server.

For a detailed explanation of docker-machine, see [Docker Machine | Docker Documentation](https://docs.docker.com/machine/).

### 1. On the remote server, grant Docker permission to sudue without a password
The docker-machine command requires root authority to operate. Since logging in as root user is usually not possible, create a user for docker and grant privilege to execute sudo command without password.
```
server$ sudo visudo
```

A sample line to add with the visudo command. Please change DOCKER_USER_NAME to the user name for docker.
```visudo
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: ALL
```

Note: This change is vulnerable to the server. After installing docker-server, recommend that modify the file so that only docker and docker-compose commands can be executed without a password.
```visudo
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: /usr/bin/docker
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: /usr/bin/docker-compose
```

### 2. Enabling docker-server
Setup is only one command.
The following command assumes VPS. For cloud servers, please change `-d generic`. The main driver list is in [Docker Machine drivers](https://docs.docker.com/machine/drivers/).
If the name of the cloud server you are using does not exist in the above driver list, try searching with "docker machine driver CROUD_SERVER_NAME".
```
$ docker-machine create --debug -d generic --generic-ip-address SERVER_IP_ADDRESS --generic-ssh-port 22 --generic-ssh-user SSH_USER_NAME SERVER_HOST_NAME
```

About options:
* generic-ip-address: IP address of the VPS server.
* generic-ssh-port: SSH port number of the VPS server (default is port 22).
* generic-ssh-user: User name to use when connecting to the VPS server.

SERVER_HOST_NAME can specify an arbitrary name like a host name that can be specified with `docker run`. For details of the command, see [docker-machine create](https://docs.docker.com/machine/reference/create/).


It takes a while to prepare the VPS (host server side), but installation will be completed if the following log is output.
```
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env SERVER_HOST_NAME
```

### 3. Install docker-compose on remote server
Just by running the `docker-machine create` command, the `docker-compose` command will not be installed on the remote server. It must be installed directly on the remote server.
```
$ docker-machine ssh SERVER_HOST_NAME "sudo apt-get install -y docker-compose"
```

### 4. Create a virtual shared network
By creating a virtual shared network, the reverse proxy recognizes all services on the created virtual sharing network, and sets VirtualHost etc based on individual environment variables.
```
$ docker-machine ssh SERVER_HOST_NAME "sudo docker network create --driver bridge SHARED_NETWORK_NAME"
```

The virtual shared network name is described as the default network setting on `docker-compose.yml`.
```/proxy/docker-compose.yml
networks:
  default:
    external:
      name: SHARED_NETWORK_NAME
```

If you don't use docker-compose, you can also set up the network with `docker run --network=SHARED_NETWORK_NAME`.
For a detailed description of docker-machine please refer to [Docker container networking | Docker Documentation](https://docs.docker.com/engine/userguide/networking/).

### 5. Synchronize data from the local machine to the remote server
Install rsync, Lsyncd, Lua using Homebrew.
```
$ brew install rsync lsyncd lua
```

`lsyncd/proxy.lua` in Docker Machine for Development is a configuration file for synchronizing the proxy sample directory to the remote server. Please rewrite the contents as necessary and execute.
Refer to [Lsyncd - Config Layer 4: Default Config](https://axkibe.github.io/lsyncd/manual/config/layer4/) for a detailed explanation of the Lsyncd configuration file.

You need root privileges to run Lsyncd. When Lsyncd is executed using sudo, the contents of the specified directory are synchronized to the remote server.
```
$ sudo lsyncd -log scarce /path/to/lsyncd/proxy.lua
```

In the sample configuration file, it's set not to start as a daemon. Started as a daemon, you can terminate the process by executing the following command.
```
$ sudo kill -KILL $(cat /var/log/lsyncd-proxy.pid)
```

Note: OSX provides the FSEvents API (similar to the Linux inotify API). Therefore, it is smart to use FSEvents in the future.

### 6. Starting the reverse proxy
Start the reverse proxy on the server.
```
$ docker-machine ssh SERVER_HOST_NAME "cd /path/to/proxy && docker-compose build && docker-compose up -d"
```

You can check the start status by doing `docker ps` on the server. In other words, if you are in ssh connection, you can use all docker commands in the same way you run the docker command on the local machine.
```
$ docker-machine ssh SERVER_HOST_NAME "docker ps"
```

### 7. Operation check
In the `proxy/docker-compose.yml` in Docker Machine for Development, **web** and **whoami** services are provided.
Please access VirtualHost set by each environment variable from the local machine. If you can confirm that the screen is displayed correctly, the setting is completed.


## Advanced Setting

This is a description on how to configure HTTP Proxy in detail.

HTTP Proxy uses the `environment` and `expose` items of each docker container. It is the following part in `docker-compose.yml`.
```/proxy/docker-compose.yml
environment:
  - ALLOW_DOMAIN=192.168.0.3,192.168.1.5  # Basic authentication is not required when accessing from the specified IP address.
  - VIRTUAL_HOST=your.domain,www.your.domain
  - LETSENCRYPT_HOST=your.domain,www.your.domain
  - LETSENCRYPT_EMAIL=letsencrypt-admin@your.domain
  # - LETSENCRYPT_TEST=true
expose:
  - "80"
```

### environment
In the environment variable, it is possible to set the VirtualHost name, permission to access from a specific domain, and domain name when using Let's Encrypt.

#### VIRTUAL_HOST
Write the VirtualHost name. Separate multiple entries with a comma.

#### ALLOW_DOMAIN
Accepts the syntax permitted by [Module ngx_http_access_module](http://nginx.org/en/docs/http/ngx_http_access_module.html#allow). Separate multiple entries with a comma.

#### LETSENCRYPT_*
* LETSENCRYPT_HOST: Describe the domain name you want to authenticate with Let's Encrypt. Separate multiple entries with a comma.
* LETSENCRYPT_EMAIL: Write mail address managing the domain name you want to authenticate with Let's Encrypt.
* LETSENCRYPT_TEST: When true, it operates in staging mode (SSL certificate issued by self certificate authority).

For a detailed explanation of Let's Encrypt, please refer to [Let's Encrypt - Free SSL/TLS Certificates](https://letsencrypt.org/).

### expose
The port number to be released on the virtual network. The proxy container can only access docker containers whose ports are open on the same virtual network as the reverse proxy.

Normally, container groups created by docker-compose individually create virtual networks and they do not exist on the same network. The docker container you want to reverse from the proxy should have access to the same virtual shared network as the proxy.

For details, refer to **4. Create a virtual shared network**.

### Basic Authentication

By creating the htpasswd file with the domain name as the file name, you can request basic authentication when accessing a specific domain.
By creating a file of VirtualHost name in the `proxy/config/htpasswd` directory, basic authentication is automatically requested when accessing the corresponding VirtualHost.

When creating the first user:
```
$ htpasswd -c /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name
```

When creating the second and subsequent users:
```
$ htpasswd /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name_2
```

---

Enjoy your Docker Machine Life!


License
---
MIT License
