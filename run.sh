#!/bin/bash

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

DBUSER="zabbix"
DBPASSWD="aaa123aa"

IMG_ZABBIXDB="zabbix/zabbix-db-mariadb"
IMG_ZABBIX="zabbix/zabbix-3.0:3.0.1"

CONT_ZABBIXDB="zabbix-db"
CONT_ZABBIX="zabbix"

EXPORT_MYSQL_PORT="33060"
EXPORT_ZWEB_PORT="8880"
EXPORT_ZSRV_PORT="10051"

DB_DIR="db"

############################################
echo "ensure db dir"
mkdir -p ${DB_DIR}

############################################
echo "start container 'zabbix-db'"
docker ps -a | grep "${IMG_ZABBIXDB}.*${CONT_ZABBIXDB}$" >/dev/null 2>&1
if [ $? -eq 0 ];then
  echo "container ${CONT_ZABBIXDB} has already started"
else
  docker run \
       -d \
       --name ${CONT_ZABBIXDB} \
       -v $(pwd)/${DB_DIR}:/var/lib/mysql \
       -p ${EXPORT_MYSQL_PORT}:3306 \
       --env="MARIADB_USER=${DBUSER}" \
       --env="MARIADB_PASS=${DBPASSWD}" \
       --env="DB_innodb_buffer_pool_size=768M" \
       ${IMG_ZABBIXDB}
fi

############################################
echo "start container 'zabbix'"
docker ps -a | grep "${IMG_ZABBIX}.*${CONT_ZABBIX}$" >/dev/null 2>&1
if [ $? -eq 0 ];then
  echo "container ${CONT_ZABBIX} has already started"
else
  docker run \
      -d \
      --name ${CONT_ZABBIX} \
      -p ${EXPORT_ZWEB_PORT}:80 \
      -p ${EXPORT_ZSRV_PORT}:10051 \
      -v /etc/localtime:/etc/localtime:ro \
      --link ${CONT_ZABBIXDB}:zabbix.db \
      --env="ZS_DBHost=zabbix.db" \
      --env="ZS_DBUser=${DBUSER}" \
      --env="ZS_DBPassword=${DBPASSWD}" \
      ${IMG_ZABBIX}
fi

echo "Done!"
cat <<EOF
========================================
  Zabbix web UI:
    http://127.0.0.1:${EXPORT_ZWEB_PORT}

  Zabbix default account:
    admin / zabbix
========================================
EOF
