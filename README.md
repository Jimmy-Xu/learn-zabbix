run zabbix server in container, then add host to monitor
========================================================

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [start zabbix server container](#start-zabbix-server-container)
- [install zabbix agent](#install-zabbix-agent)
	- [install](#install)
	- [config](#config)
	- [start service](#start-service)
- [test connection](#test-connection)
- [add host in Zabbix web UI](#add-host-in-zabbix-web-ui)
	- [login Zabbix web UI](#login-zabbix-web-ui)
	- [add host](#add-host)
	- [add host into template](#add-host-into-template)
	- [view graph](#view-graph)
- [encryption between zenbbix server and agent](#encryption-between-zenbbix-server-and-agent)
	- [config zenbbix agent](#config-zenbbix-agent)
	- [test connection with encryption](#test-connection-with-encryption)
	- [add host in Zabbix web UI with encryption](#add-host-in-zabbix-web-ui-with-encryption)

<!-- /TOC -->

> **zabbix server**: `192.168.1.137`  
> **zabbix agent**: `192.168.1.110`  

# start zabbix server container

> run zabbix server container on `192.168.1.137`  

```
$ ./run.sh
$ docker ps | grep zabbix
  9469b335ced4  zabbix/zabbix-3.0:3.0.1   "/config/bootstrap.sh"   2 hours ago   Up 2 hours    162/udp, 0.0.0.0:10051->10051/tcp, 0.0.0.0:8880->80/tcp   zabbix
  6f588e238432  zabbix/zabbix-db-mariadb  "/run.sh"                2 hours ago   Up 2 hours    0.0.0.0:33060->3306/tcp                                              zabbix-db
```

# install zabbix agent

> run zabbix agent on `192.168.1.110`  

## install
```
$ sudo  rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
$ sudo yum install zabbix-agent
```

## config
```
//edit /etc/zabbix/zabbix_agentd.conf
  Server=192.168.1.137
  ServerActive=192.168.1.137
```

## start service
```
$ sudo service zabbix-agent start
```

# test connection
```
$ docker exec -it zabbix bash
  [root@9469b335ced4 zabbix]# zabbix_get -s 192.168.1.110 -p 10050 -k "system.uptime"
  6392
  [root@9469b335ced4 zabbix]# zabbix_get -s 192.168.1.110 -p 10050 -k "agent.ping"
  1
```

# add host in Zabbix web UI

##  login Zabbix web UI
```
open http://192.168.1.137:8880/ in web browser
default account: admin/zabbix
```

## add host
```
Mainmenu -> Configuration -> Hosts -> "Create host"

example:
	Host name: vm-centos7
	Groups: Linux Servers
	Agent interface:
		IP Address: 192.168.1.110
		PORT: 10050
```

## add host into template
```
Mainmenu -> Configuration -> Templates

example:
	Template OS Linux
		add host vm-centos7 into "Hosts / templates" list
```

## view graph
```
Mainmenu -> Monitoring -> Graphs

example:
	Group: all
	Host: vm-centos7
	Graph: Memory usage
```

# encryption between zenbbix server and agent

## config zenbbix agent

```
//generate psk
$ openssl rand -hex 32 | sudo tee /etc/zabbix/zabbix_agentd.psk

//add the following line into /etc/zabbix/zabbix_agentd.conf
TLSConnect=psk
TLSAccept=psk
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
TLSPSKIdentity=PSK 001

//restart zabbix-agent
$ systemctl restart zabbix-agent

```

## test connection with encryption

> copy psk file to `/etc/zabbix/zabbix_agentd.psk` of zenbbix server

```
$ docker exec -it zabbix bash
  [root@9469b335ced4 zabbix]# zabbix_get -s 192.168.1.110 -p 10050 -k "system.uptime"
	zabbix_get [5804]: Check access restrictions in Zabbix agent configuration

	[root@9469b335ced4 zabbix]# zabbix_get -s 192.168.1.110 -p 10050 -k "system.uptime" --tls-connect=psk --tls-psk-identity="PSK 001" --tls-psk-file=/etc/zabbix/zabbix_agentd.psk
	17158
```

## add host in Zabbix web UI with encryption

```
Mainmenu -> Configuration -> Hosts -> vm-centos7 -> Encryption -> PSK
	Connections from host: PSK (check)
	PSK identity: PSK 001
	PSK: xxxxxxxxxxxxx

//PSK is the content in /etc/zabbix/zabbix_agentd.psk
```
