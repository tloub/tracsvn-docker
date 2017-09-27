#!/bin/bash

source .env

if [ -d /var/log/apache2/ ] 
then echo "cannot create directory '/var/log/apache2/': File exists"
else mkdir /var/log/apache2/
fi
cat <<EOF >>/etc/apache2/sites-available/usvn.conf
ServerTokens Prod
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com

        ServerAdmin webmaster@localhost
	ServerName $(echo $SERVER_NAME) 
        DocumentRoot /var/www

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
        Alias /svnadmin /usr/local/lib/usvn/public
        <Directory "/usr/local/lib/usvn/public">
                AllowOverride All
                Options +SymLinksIfOwnerMatch
                Require all granted
        </Directory>
        <Location /svn/>
                ErrorDocument 404 default
                DAV svn
                #SVNUseUTF8 on
                Require valid-user
                SVNParentPath /var/local/svn/svn/
                SVNListParentPath off
                AuthType Basic
                AuthName "USVN"
                AuthUserFile /var/local/svn/htpasswd
                AuthzSVNAccessFile /var/local/svn/authz
        </Location>
        WSGIScriptAlias /trac /usr/local/lib/trac/apache/trac.wsgi
        <Directory /usr/local/lib/trac/apache>
                WSGIApplicationGroup %{GLOBAL}
                AllowOverride All
                Require all granted
        </Directory>
        #<LocationMatch "/trac/[^/]+/login"> # Conf par défaut, désactivée car aucun de nos trac ne doit être public
        <LocationMatch "/trac">
		AuthType Basic
		AuthName "Authentification Trac"
                AuthUserFile /var/local/svn/htpasswd
                Require valid-user
        </LocationMatch>
        Alias /tracstatic /usr/local/lib/trac/htdocs
</VirtualHost>
EOF
echo "<IfModule dir_module>
        DirectoryIndex index.html index.php
</IfModule>" >> /etc/apache2/mods-available/php7.0
a2enmod rewrite
a2enmod dav_svn
a2dissite 000-default.conf
a2ensite usvn && service apache2 restart
cat /etc/apache2/sites-available/usvn.conf

IP_ADDR=$(ip a | grep 172.* | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

################################ CONFIGURING AND INSTALLING USVN ################################
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=2' -d language="fr_FR" -d timezone="Europe/Paris"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=3' -d language="fr_FR" -d timezone="Europe/Paris"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=4' -d agreement="ok"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=5' -d title="USVN" -d pathSubversion="/var/local/svn" -d passwdFile="/var/local/svn/htpasswd" -d authzFile="/var/local/svn/authz" -d urlSubversion="http://$(echo $SERVER_NAME)/svnadmin/svn"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=6' -d adapter="PDO_MYSQL" -d host="usvn_db" -d user="root" -d password="$(echo $PASS_BDD_USVN)" -d database="$(echo $MYSQL_DATABASE)" -d prefix="$(echo $MYSQL_DATABASE)_"
curl 'http://'$IP_ADDR'/svnadmin/install.php?step=7' -d login="admin" -d firstname="admin" -d lastname="Administrateur" -d password="$PASS_USER" -d password2="$(echo $PASS_USER)" -d email="$(echo $MAIL_ADDRESS)"
cat <<EOF >/usr/local/lib/usvn/config/config.ini
[general]
url.base = "/svnadmin"
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
database.prefix = "$(echo $MYSQL_DATABASE)_"
database.options.host = "usvn_db"
database.options.username = "root"
database.options.password = "$(echo $PASS_BDD_USVN)"
database.options.dbname = "$(echo $MYSQL_DATABASE)"
update.checkforupdate = "0"
update.lastcheckforupdate = "1493739172"
version = "1.0.7"
EOF
