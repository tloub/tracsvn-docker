#!/bin/bash

################################ SETTING UP TRAC ################################
mkdir -p /usr/local/lib/trac/apache
mkdir -p /var/local/trac/eggs
mkdir /var/local/trac/sites
touch /usr/local/lib/trac/apache/trac.wsgi
echo "import sys
sys.stdout = sys.stderr
import os
os.environ['TRAC_ENV_PARENT_DIR'] = '/var/local/trac/sites'
os.environ['PYTHON_EGG_CACHE'] = '/var/local/trac/eggs'
import trac.web.main
application = trac.web.main.dispatch_request "  >  /usr/local/lib/trac/apache/trac.wsgi
chown www-data /var/local/trac/eggs

################################ PREPARING TRAC PLUGINS  ##############################
mkdir -p /usr/local/etc/trac/plugins
ln -nfs /usr/local/lib/python2.7/dist-packages/TracIniAdminPanel-1.0.2-py2.7.egg  /usr/local/etc/trac/plugins

################################ SERVICES SECURISATION ################################
chmod -R o-rwx /var/local/svn /var/local/trac
chown -R www-data /var/local/svn /var/local/trac
