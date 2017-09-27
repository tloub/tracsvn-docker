#!/bin/bash

################################ Prerparing USVN ################################ 
wget https://github.com/usvn/usvn/archive/1.0.7.tar.gz
tar xvzf 1.0.7.tar.gz
mkdir /var/local/svn
chown -R root:root usvn-1.0.7/
chown -R www-data usvn-1.0.7/config usvn-1.0.7/public /var/local/svn
mv usvn-1.0.7 /usr/local/lib/usvn
cp /htpasswd /var/local/svn/htpasswd
cp /authz /var/local/svn/authz
rm /htpasswd
rm /authz
