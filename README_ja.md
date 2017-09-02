# Docker Machine for Development

このリポジトリは、docker-machineを使用してリモートサーバーを開発環境にするために必要な最小限の機能をまとめたものです。
Machintosh用に作られたものですが、少し修正を加えることで、WindowsやLinux上でも動作します。（dockerとLsyncd、rsync、Luaが動作する環境を用意する必要があります）

## 概要

Docker Machine for Developmentは、リモートサーバー上で開発環境向けにDockerを実行するために必要な最小構成を用意しています。
リポジトリ内の docker-compose を docker-machine を利用してリモートサーバーに導入することで、ローカルマシンの演算能力を使用することなく、リモートサーバーの豊富なリソースを利用してDockerコンテナを起動し、快適に開発を行うことができます。

主な機能:

* VirtualHost名を使用して、サーバー上で動作する様々なdockerコンテナにアクセスすることが可能です。
* VirtualHostごとにBasic認証のID/パスワードを設定することが可能です。
* 特定のIPアドレスからのアクセス時に、Basic認証を使わない設定を行うことが可能です。
* ローカルマシン上で修正された内容は（ほとんど）遅延なくリモートサーバーに反映されます。
* もちろん、Dockerをローカルマシンで動かすことも可能です。

すべての基本設定はこのリポジトリに格納されています。
リポジトリをフォークまたはクローンし、必要な箇所を変更するだけで利用を開始できます。

### HTTP Proxy (nginxベース)
これはnginxベースのリバースプロキシサーバです。HTTP及びHTTPSでのアクセスに対応しています。
リモートサーバーのdockerコンテナへのアクセスは、原則としてこのproxyサーバー（dockerコンテナ）を経由してアクセスする形式を取ります。

このproxyサーバーには、Let's EncryptでSSH証明書を発行する機能が含まれています。
Let's Encryptの動作モードは、stagingモードをデフォルトに設定しています。
環境変数 `ACME_CA_URI` をコメントアウトすると、productionモードで動作します。
また、個々のdockerコンテナでstagingモードを設定するために、環境変数 `LETSENCRYPT_TEST` が用意されています。

さらに、VirtualHostで名前解決を行うこともできます。
VirtualHostによる名前解決は、同じサーバー上で実行されている他のdockerコンテナに対しても有効です。 他のdockerコンテナを起動すると、プロキシサーバーはそれを検出し、名前解決を自動的に実行します。
この機能を使用するには、プロキシドッカーサーバーと他のドッカーサーバーが同じ仮想ネットワーク上に存在する必要があります。
また、環境変数 `VIRTUAL_HOST` を利用する必要があります。

各VirtualHostに対するBasic認証の設定方法と、特定のIPアドレスからアクセスが来た時にBasic認証を使わない方法については、「詳細設定」の項目で説明します。


### Lsyncd + rsync
この機能は、ローカルマシンで行われた変更をすぐにリモートサーバーに反映させるためのものです。 Lsyncdが指定されたディレクトリ以下の変更を検出し、rsyncはリモートサーバへの変更を直ちに反映します。
どのディレクトリを検知対象にし、どのファイルをアップロード対象外にするかは、Luaで記述されている設定ファイルでカスタマイズ可能です。

リモートサーバー上で動作しているdockerコンテナは、rsyncを経由してリモートサーバー上で変更されたファイルを検出することができます。従ってほとんどの場合（dockerコンテナを再起動することなく）開発中のアプリケーションを再ロードするだけでファイルの変更を確認できます。

注意: dockerコンテナ起動時に読み込み、その後ファイルの変更を検知しないファイルを修正した場合は、ローカルマシンで開発する場合と同様にコンテナの再起動が必要です。

## 対象ユーザー

Docker Machine for Developmentは、十分なマシンパワーを持たないローカルマシンで開発を行う人のために用意されています。
ただし、開発用の（リモート）サーバーを準備できるユーザーを対象としています。

想定している主な利用シーン:

* 十分なマシンパワーを持たないため、ローカルマシン上でDockerを満足に動作させることができない開発者。
* さまざまなプロジェクトを同時に開発する必要がある開発者。
* 複数のスマートフォンやPCで、複数バージョンのブラウザを利用して同時にテストと修正を行う必要があるプロジェクト。
* リモートワークを行っているなど、さまざまな環境から開発サーバーにアクセスする必要があるプロジェクト。

推奨しない利用シーン:

* 本番環境の運用。Dockerを利用した本番環境の運用実績が少ないため、お勧めできません。
* ローカルマシンのスペックが高く、他の人と共同作業をしていない人。ローカルマシンでDockerを動かしてください。
* Terminal（黒い画面）を操作することに抵抗がある人。GUIは用意していません。
* Docker初心者の人。まずはローカルでDockerを動かすことに慣れてください。

上記のケースでは、ローカルマシン上でDockerを動かす方がより使いやすいでしょう。


## 使い方

[Docker for Mac](https://docs.docker.com/docker-for-mac/) と [Homebrew](https://brew.sh/index_ja.html) が既にインストールされている前提です。
また、リモートサーバーには Ubuntu 16.04 を利用しています。

docker-machine の詳細な説明は [Docker Machine | Docker Documentation](https://docs.docker.com/machine/) を参照してください。

### 1. リモートサーバー上で、Dockerがパスワード無しでsuduできる権限を付与する
docker-machine コマンドの動作には、root権限が必要です。rootユーザーでのログインは通常できないため、docker用のユーザーを作成し、パスワード無しでsudoコマンドを実行できる権限を付与します。
```
server$ sudo visudo
```

visudo コマンドで追加する行のサンプルです。DOCKER_USER_NAMEは、docker用のユーザー名に書き換えてください。
```visudo
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: ALL
```

注意: この変更はサーバーに対して脆弱性を与えます。docker-serverのインストール後、dockerコマンドとdocker-composeコマンドだけをパスワード無しで実行できるよう、ファイルを修正することを推奨します。
```visudo
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: /usr/bin/docker
DOCKER_USER_NAME  ALL=(ALL:ALL)   NOPASSWD: /usr/bin/docker-compose
```

### 2. docker-server を使用できるようにする
セットアップはコマンド一つだけです。
以下のコマンドはVPSを想定しています。クラウドサーバーの場合は `-d generic` を書き換えてください。主なドライバ一覧は [Docker Machine drivers](https://docs.docker.com/machine/drivers/) にあります。
上記のドライバ一覧に、使用しているクラウドサーバーの名前が存在しない場合は「docker machine driver CROUD_SERVER_NAME」で検索してみてください。例えば、さくらのクラウドであれば [SAKURA CLOUD driver for docker-machine](https://github.com/yamamoto-febc/docker-machine-sakuracloud) が提供されています。
```
$ docker-machine create --debug -d generic --generic-ip-address SERVER_IP_ADDRESS --generic-ssh-port 22 --generic-ssh-user SSH_USER_NAME SERVER_HOST_NAME
```

オプションについて:
* generic-ip-address: VPSサーバーのIPアドレス
* generic-ssh-port: VPSサーバーのSSHポート番号（デフォルトは22番ポート）
* generic-ssh-user: VPSサーバーに接続する際に利用するユーザー名

SERVER_HOST_NAME は `docker run` で指定可能なホスト名のように、任意の名前を指定可能です。コマンドの詳細は [docker-machine create](https://docs.docker.com/machine/reference/create/) を見てください。


VPS (ホストサーバー側) の準備に少し時間がかかりますが、以下のログが出力されれば、インストール完了です。
```
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env SERVER_HOST_NAME
```

### 3. docker-compose をリモートサーバーにインストールする
`docker-machine create` コマンドを実行しただけでは、 `docker-compose` コマンドはリモートサーバーにインストールされません。`docker-compose` コマンドは直接リモートサーバーにインストールする必要があります。
`docker-machine ssh` コマンドを利用することで、設定済みの docker-machine ホストに ssh 接続することが可能です。
```
$ docker-machine ssh SERVER_HOST_NAME "sudo apt-get install -y docker-compose"
```

### 4. 仮想共有ネットワークを作成する
仮想共有ネットワークを作成することで、作成した仮想共有ネットワーク上にある全てのサービスをリバースプロキシが認識し、個々の環境変数に基づいてVirtualHost等の設定を行います。
```
$ docker-machine ssh SERVER_HOST_NAME "sudo docker network create --driver bridge SHARED_NETWORK_NAME"
```

仮想共有ネットワーク名は、 `docker-compose.yml` 上でデフォルトネットワーク設定として記述します。
```/proxy/docker-compose.yml
networks:
  default:
    external:
      name: SHARED_NETWORK_NAME
```

docker-composeを利用しない場合は `docker run --network=SHARED_NETWORK_NAME` でネットワーク設定を行うこともできます。
docker-machine の詳細な説明は [Docker container networking | Docker Documentation](https://docs.docker.com/engine/userguide/networking/) を参照してください。

### 5. ローカルマシンからリモートサーバーへデータを同期する
Homebrew を利用して rsync, Lsyncd, Lua をインストールします。
```
$ brew install rsync lsyncd lua
```

Docker Machine for Development 内の `lsyncd/proxy.lua` は、proxyのサンプルディレクトリをリモートサーバーへ同期するための設定ファイルです。必要に応じて内容を書き換えて実行してください。
Lsyncd の設定ファイルに関する詳細な説明は [Lsyncd - Config Layer 4: Default Config](https://axkibe.github.io/lsyncd/manual/config/layer4/) を参照してください。

Lsyncdの実行にはroot権限が必要です。sudoを利用してLsyncdを実行すると、指定したディレクトリの内容がリモートサーバーへ同期されます。
```
$ sudo lsyncd -log scarce /path/to/lsyncd/proxy.lua
```

サンプルの設定ファイルではデーモンとして起動しない設定になっています。デーモンとして起動した場合は、以下のコマンドを実行することでプロセスを終了させることができます。
```
$ sudo kill -KILL $(cat /var/log/lsyncd-proxy.pid)
```

注意: OSXではFSEvents API（Linuxのinotify APIに似ている）が用意されています。そのため、将来はFSEventsを利用するのがスマートです。

### 6. リバースプロキシの起動
サーバー上でリバースプロキシを起動します。
```
$ docker-machine ssh SERVER_HOST_NAME "cd /path/to/proxy && docker-compose build && docker-compose up -d"
```

サーバー上で `docker ps` を行うことで、起動状態の確認が可能です。つまり、ssh接続をした状態であれば、ローカルマシン上でdockerコマンドを実行するのと同じように、全てのdockerコマンドが利用できるということです。
```
$ docker-machine ssh SERVER_HOST_NAME "docker ps"
```

### 7. 動作確認
Docker Machine for Development 内の `proxy/docker-compose.yml` 内に、 **web** と **whoami** サービスが用意されています。
それぞれの環境変数で設定しているVirtualHostに対し、ローカルマシンからアクセスを行ってください。正しく画面が表示されることが確認できれば、設定は完了しています。


## 詳細設定

HTTP Proxyの詳細設定方法についての説明です。

HTTP Proxyは、各dockerコンテナの`environment`及び`expose`の項目を利用しています。 `docker-compose.yml` に記載されている以下の部分です。
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
環境変数では、VirtualHost名の設定及び特定ドメインからのアクセス許可、Let's Encryptを利用する場合のドメイン名を設定することが可能です。

#### VIRTUAL_HOST
VirtualHost名を記述します。複数記述する場合は、カンマで区切ります。

#### ALLOW_DOMAIN
[Module ngx_http_access_module](http://nginx.org/en/docs/http/ngx_http_access_module.html#allow) で許可されているシンタックスを受け付けます。複数記述する場合は、カンマで区切ります。

#### LETSENCRYPT_*
* LETSENCRYPT_HOST: Let's Encrypt で認証したいドメイン名を記述します。複数記述する場合は、カンマで区切ります。
* LETSENCRYPT_EMAIL: Let's Encrypt で認証したいドメイン名を管理しているメールアドレスを記述します。
* LETSENCRYPT_TEST: trueの時、stagingモード（自己認証局によって発行されたSSL証明書）で動作します。

Let's Encrypt に関する詳細な説明は [Let's Encrypt 総合ポータル](https://letsencrypt.jp/) を参照してください。

### expose
仮想ネットワーク上に開放するポート番号です。プロキシコンテナがアクセスできるのは、リバースプロキシと同じ仮想ネットワーク上にポートが開放されているdockerコンテナに限ります。

通常、docker-composeで作成したコンテナグループは、個別に仮想ネットワークを作成し、それらが同じネットワーク上に存在しません。プロキシからリバースしたいdockerコンテナは、プロキシと同じ仮想共有ネットワークにアクセスできるようにしてください。

詳しくは **4. 仮想共有ネットワークを作成する** を参考にしてください。

### Basic認証

ドメイン名をファイル名としてhtpasswdファイルを作成することで、特定ドメインにアクセスした際にBasic認証を要求することができます。
`proxy/config/htpasswd` ディレクトリ内にVirtualHost名のファイルを作成することで、該当するVirtualHostにアクセスが来た際に自動的にBasic認証が要求されます。

最初のユーザーを作成するとき:
```
$ htpasswd -c /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name
```

2番目以降のユーザーを作成するとき:
```
$ htpasswd /path/to/proxy/config/htpasswd/www.your.domain basic_auth_name_2
```

---

Enjoy your Docker Machine Life!


License
---
MIT License