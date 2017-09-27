#!/bin/bash

IP_ADDR=$(ip a | grep 172.* | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

################################ CONFIGURING AND INSTALLING USVN ################################
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=2' -d language="fr_FR" -d timezone="Europe/Paris"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=3' -d language="fr_FR" -d timezone="Europe/Paris"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=4' -d agreement="ok"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=5' -d title="USVN" -d pathSubversion="/var/local/svn" -d passwdFile="/var/local/svn/htpasswd" -d authzFile="/var/local/svn/authz" -d urlSubversion="http://$(echo $SERVER_NAME)/svnadmin/svn"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=6' -d adapter="PDO_MYSQL" -d host="usvn_db" -d user="root" -d password="$(echo $PASS_BDD_USVN)" -d database=usvn -d prefix=usvn_
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=7' -d login="admin" -d firstname="admin" -d lastname="Administrateur" -d password="bobo" -d password2="bobo" -d email="svnadmins@iorga.com"
echo "[general]
url.base = \"/svnadmin\"
translation.locale = "fr_FR"
timezone = "Europe/Paris"
system.locale = "C.UTF-8"
template.name = "usvn"
site.title = "USVN"
site.ico = "medias/usvn/images/logo_small.tiff"
site.logo = "medias/usvn/images/logo_trans.png"
subversion.path = "/var/local/svn/"
subversion.passwd = "/var/local/svn/htpasswd"
subversion.authz = "/var/local/svn/authz"
subversion.url = "http://$(echo $SERVER_NAME)/svn/"
database.adapterName = "PDO_MYSQL"
database.prefix = "usvn_"
database.options.host = "usvn_db"
database.options.username = "root"
database.options.password = "$(echo $PASS_BDD_USVN)"
database.options.dbname = "usvn"
update.checkforupdate = "0"
update.lastcheckforupdate = "1493739172"
version = "1.0.7" " > /usr/local/lib/usvn/config/config.ini

