FROM ubuntu:16.04

LABEL maintainer="tloubaresse@iorga.com"

################################# DEPENDENCIES INSTALLATION #################################
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
	cpanminus -y \
	debconf \
	python-pip \
	php-xml \
#RUN add-apt-repository ppa:certbot/certbot -y
#RUN apt-get update && apt-get install -y apt-utils \
#	dialog
	curl \
	wget \
	vim  \
	subversion \
	apache2 \
	libapache2-svn \
	php \
	php-mysql \
	libapache2-mod-php \
	libapache2-mod-wsgi \
	python-subversion \
	p7zip-full \
	software-properties-common \
#	python-certbot-apache \
	iproute \
	php-cli

RUN pip install --upgrade pip
RUN pip install setuptools
RUN pip install -U Genshi \
	TracTags
RUN easy_install Babel==0.9.6 \
	Trac \
	pytz \
	https://trac-hacks.org/svn/iniadminplugin/0.11 \
        https://trac-hacks.org/svn/traciniadminpanelplugin/trunk/#egg=TracIniAdminPanelPlugin-dev \
        https://trac-hacks.org/svn/announcerplugin/trunk  \
        https://trac-hacks.org/svn/customfieldadminplugin/0.11
RUN easy_install --upgrade pytz 
RUN apt-get clean

################################# PREPARING SERVER RES0LUTION #################################
#ADD install_server.sh /install_server.sh
#RUN ["/bin/sh", "/install_server.sh"]

################################# ADDING NECESSARY FILES FOR CONFIGURATION #################################
ADD compose-files/data_svn/htpasswd /htpasswd
ADD compose-files/data_svn/authz /authz
ADD .env .env

################################ DOWNLOADING USVN #################################
ADD download_usvn.sh /download_usvn.sh
RUN ["/bin/sh", "/download_usvn.sh"]

################################# SETTING UP TRAC ################################
ADD install_trac.sh /install_trac.sh
RUN ["/bin/sh", "/install_trac.sh"]

############################## SETTING UP APACHE2 ################################
ADD install_apache.sh /install_apache.sh
RUN ["/bin/bash", "/install_apache.sh"]

################################ MODIFICATION OF SQL FILES ################################
ADD install_sql.sh /install_sql.sh
RUN ["/bin/sh", "/install_sql.sh"]

################################ ADDING SCRIPTS ################################
ADD add_files.sh /add_files.sh
RUN ["/bin/sh", "/add_files.sh"]

################################ CLEANING UP SCRIPTS ################################
RUN rm download_usvn.sh install_trac.sh install_apache.sh install_sql.sh add_files.sh .env

CMD apachectl -D FOREGROUND
