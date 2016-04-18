run zabbix server in container, then add host to monitor
========================================================

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [start zabbix server container](#start-zabbix-server-container)
- [install zabbix agent](#install-zabbix-agent)
	- [install on bare metal server](#install-on-bare-metal-server)
		- [install from rpm](#install-from-rpm)
		- [config](#config)
		- [start service](#start-service)
	- [install on AWS Linux AMI](#install-on-aws-linux-ami)
		- [install from zabbix source](#install-from-zabbix-source)
		- [config file](#config-file)
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
- [discovery and auto add host](#discovery-and-auto-add-host)
	- [discovery config](#discovery-config)
	- [auto add host](#auto-add-host)
- [send notification email by SES](#send-notification-email-by-ses)
	- [config AWS SES](#config-aws-ses)
		- [verify domain](#verify-domain)
			- [verify a New Domain](#verify-a-new-domain)
			- [add DNS record](#add-dns-record)
			- [check Verify status](#check-verify-status)
		- [verified Sender Email](#verified-sender-email)
			- [verify a New Email Address](#verify-a-new-email-address)
			- [click verify link in mailbox](#click-verify-link-in-mailbox)
			- [check verify status](#check-verify-status)
		- [get SMTP settings](#get-smtp-settings)
		- [create SMTP Credentials](#create-smtp-credentials)
	- [config Zabbix for SES](#config-zabbix-for-ses)
		- [put custom alert script into "alertscripts" dir](#put-custom-alert-script-into-alertscripts-dir)
		- [config custom alertscript in zabbix web-ui](#config-custom-alertscript-in-zabbix-web-ui)
			- [add new Media Types for SES](#add-new-media-types-for-ses)
			- [add Media Type `SES` to user](#add-media-type-ses-to-user)
- [integration zabbix with slack](#integration-zabbix-with-slack)
	- [config Slack](#config-slack)
		- [create new Channel](#create-new-channel)
		- [create new Incoming WebHooks](#create-new-incoming-webhooks)
	- [config Zabbix for slack](#config-zabbix-for-slack)
		- [put slack.sh to "alertscripts" dir](#put-slacksh-to-alertscripts-dir)
		- [config slack.sh in zabbix web-ui](#config-slacksh-in-zabbix-web-ui)
			- [add new Media Types for Slack](#add-new-media-types-for-slack)
			- [add Media Type `Slack` to user](#add-media-type-slack-to-user)

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

## install on bare metal server

### install from rpm
```
$ sudo  rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
$ sudo yum install zabbix-agent

//config file
$ ls /etc/zabbix/zabbix_agentd.conf

```

### config
```
//edit /etc/zabbix/zabbix_agentd.conf
  Server=192.168.1.137
  ServerActive=192.168.1.137
  Hostname=vm-centos7
```

### start service
```
$ sudo service zabbix-agent start
```


## install on AWS Linux AMI

> Installation from sources  
> doc: https://www.zabbix.com/documentation/3.2/manual/installation/install  

### install from zabbix source

```
$ wget http://tenet.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.1/zabbix-3.0.1.tar.gz
$ tar xzvf zabbix-3.0.1.tar.gz
$ cd zabbix-3.0.1
$ ./configure --enable-agent
$ make install
$ sudo make install

//deploy init.d config file
$ sudo cp misc/init.d/fedora/core/zabbix_agentd /etc/init.d/

//create link
$ ln -s /usr/local/sbin/zabbix_agentd /usr/sbin/zabbix_agentd
$ ln -s /usr/local/bin/zabbix_get /usr/bin/zabbix_get
$ ln -s /usr/local/bin/zabbix_sender /usr/bin/zabbix_sender

//create user and group for zabbix
$ sudo groupadd zabbix
$ sudo useradd -g zabbix zabbix
```

### config file
```
//config file
$ vi /usr/local/etc/zabbix_agentd.conf
	Server=192.168.1.137
	ServerActive=192.168.1.137
	Hostname=ec2-centos7
```

### start service
```
//enable autostart
$ chkconfig --add /etc/init.d/zabbix_agentd

//start zabbix_agentd
$ sudo service zabbix_agentd start
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

> `Host name` should be same with `Hostname` in /etc/zabbix/zabbix_agentd.conf of zabbix-agent

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

# discovery and auto add host

## discovery config
```
Mainmenu -> Configuration -> Discovery

Discovery rules:
	Name: Local network
	IP Range: 10.1.1.1-254
	Delay (in sec): 300
	Enabled: true
```

## auto add host
```
Mainmenu -> Configuration -> Actions

Actions:
	Name: Auto discovery. Linux servers.
	Enabled: true
Operations:
	Add to host groups: Linux servers
	Link to templates: Template OS Linux
```

# send notification email by SES

## config AWS SES

### verify domain

#### verify a New Domain
```
//open url
https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#verified-senders-domain:

//click 'Verify a New Domain' button
Domain: xxxxx.sh
Generate DKIM Settings: <checked>

//view detail info about xxxxx.sh, get the following info:
	Record Type: 	TXT (Text)
	TXT Name*:   	_amazonses.xxxxx.sh
	TXT Value:    QKVxxxxxxxxxxxxxxxxxxxxxxxww=

	DKIM:
		Name	                                Type 	  Value
		juyxxxxxxxxxxler._domainkey.xxxxx.sh 	CNAME 	juyxxxxxxxxxxler.dkim.amazonses.com
		gegxxxxxxxxxx63d._domainkey.xxxxx.sh 	CNAME 	gegxxxxxxxxxx63d.dkim.amazonses.com
		4wpxxxxxxxxxxfdu._domainkey.xxxxx.sh 	CNAME 	4wpxxxxxxxxxxfdu.dkim.amazonses.com
```

#### add DNS record
```
//open iwantmyname.com (example)
https://iwantmyname.com/dashboard/dns/xxxxx.sh

//add new DNS record(see above)
1 TXT record, 3 CNAME
```
#### check Verify status
```
//go back to AWS SES console,
https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#verified-senders-domain:
the 'Status' of xxxxx.sh should be green 'verified`
```

### verified Sender Email

#### verify a New Email Address
```
//open https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#verified-senders-email:

//click "Verify a New Email Address" button

//input a Email Address, for example: jimmy@xxxxx.sh
```

#### click verify link in mailbox
```
//login mailbox of jimmy@xxxxx.sh, there will be a new email with title like:
"Amazon SES Address Verification Request in region US West (Oregon)"

//click then confirm link in this mail, it will goto http://aws.amazon.com/cn/ses/verifysuccess/, that means verify success
```

#### check verify status
```
//go back to AWS SES console
https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#verified-senders-email:

//the status of jimmy@xxxxx.sh should be green 'verified`
```

### get SMTP settings
```
//open https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#smtp-settings:

//get the following info:
	Server Name:
	email-smtp.us-west-2.amazonaws.com
	Port:	25, 465 or 587
	Use Transport Layer Security (TLS):	Yes
```

### create SMTP Credentials
```
//open https://us-west-2.console.aws.amazon.com/ses/home?region=us-west-2#smtp-settings:

//click "Create My SMTP Credentials" button
	IAM username: zabbix-agent

//remember the following important info:
	Access Key Id
	Secret Access Key
```

## config Zabbix for SES

### put custom alert script into "alertscripts" dir

> https://bitbucket.org/superdaigo/zabbix-alert-smtp/src

```
//get "alertscripts" path
$ grep ^AlertScriptsPath /etc/zabbix/zabbix_server.conf
	AlertScriptsPath=/usr/lib/zabbix/alertscripts

$ cd /usr/lib/zabbix/alertscripts
$ git clone https://git@bitbucket.org:superdaigo/zabbix-alert-smtp.git
$ cd zabbix-alert-smtp
$ cat settings.py
	# Mail Account
	SENDER_NAME = u'Zabbix Alert'
	SENDER_EMAIL = 'jimmy@xxxxx.sh'
	# Amazon SES
	SMTP_USERNAME = '<Access Key Id>'
	SMTP_PASSWORD = '<Secret Access Key>'
	# Mail Server
	SMTP_SERVER = 'email-smtp.us-west-2.amazonaws.com'
	SMTP_PORT = 587
	# SSL Type ('SMTP_TLS' / 'SMTP_SSL')
	SMTP_SSL_TYPE = 'SMTP_TLS'

//test send email
$ /usr/lib/zabbix/alertscripts/zabbix-alert-smtp/zabbix-alert-smtp.sh jimmy@xxxxx.sh 'test' 'helloworld'

//check the new email in jimmy@xxxxx.sh's mailbox
```

### config custom alertscript in zabbix web-ui

> https://www.zabbix.com/documentation/3.2/manual/config/notifications/media/script  

#### add new Media Types for SES

```
Mainmenu -> Administration -> Media Types
	Create media type:
		Name: SES
		Type: Script
		Script name: zabbix-alert-smtp/zabbix-alert-smtp.sh
		Script parameters:
			{ALERT.SENDTO}
			{ALERT.SUBJECT}
			{ALERT.MESSAGE}
		Enabled: true
```
#### add Media Type `SES` to user

> set the targe email which want to received the notification mail  

```
Mainmenu -> Administration -> Users -> click Admin user -> Media -> Add
	Type           : SES
	Send to        : jimmy@xxxxx.sh
	When active    : 1-7,00:00-24:00
	Use if severity: <check all>
	Enabled        : true
```

# integration zabbix with slack

## config Slack

### create new Channel
```
create a new public channel, name is 'zabbix-alert'
```

### create new Incoming WebHooks
```
go to https://hypercrew.slack.com/apps/manage/custom-integrations
 -> Add Configuration
   -> Integration Settings
	    - Post to Channel: #zabbix-alert
	    - Webhook URL    : https://hooks.slack.com/services/T0xxxxxxK/B1xxxxxxB/QkUxxxxxxxxxxxxxxxxxxxxxxxx
	    - Customize Name : ZabbixBot
	    - Customize Icon : <Upload an image> as zabbix icon
```

## config Zabbix for slack

> https://github.com/ericoc/zabbix-slack-alertscript  

### put slack.sh to "alertscripts" dir
```
//1. get AlertScriptsPath
$ grep ^AlertScriptsPath /etc/zabbix/zabbix_server.conf
  AlertScriptsPath=/usr/lib/zabbix/alertscripts

//2. get slack.sh from https://github.com/ericoc/zabbix-slack-alertscript, and put it in ${AlertScriptsPath}
//modify url and username in slack.sh
url='https://hooks.slack.com/services/T0xxxxxxK/B1xxxxxxB/QkUxxxxxxxxxxxxxxxxxxxxxxxx'
username='ZabbixBot'

//3. test slack.sh, #zabbix-alert channel will receive the following message when configure correct
$ ./slack.sh '#zabbix-alert' PROBLEM 'Oh no! Something is wrong!'
  ok
$ ./slack.sh '@jimmy' PROBLEM 'Oh no! Something is wrong!'
  ok
```

### config slack.sh in zabbix web-ui

#### add new Media Types for Slack

```
Mainmenu -> Administration -> Media Types
	Create media type:
		Name: Stack
		Type: Script
		Script name: slack.sh
		Script parameters:
			{ALERT.SENDTO}
			{ALERT.SUBJECT}
			{ALERT.MESSAGE}
		Enabled: true
```

#### add Media Type `Slack` to user

> set the targe email which want to received the notification mail  

```
Mainmenu -> Administration -> Users -> click Admin user -> Media -> Add
	Type           : Stack
	Send to        : #zabbix-monitor
	When active    : 1-7,00:00-24:00
	Use if severity: <check all>
	Enabled        : true
```
