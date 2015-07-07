#!/bin/bash
#Version: 1.4.7
#Author: MapFig
#OS Tested: Ubuntu 14.04.2.x64 LTS (recommended) and Ubuntu 14.10-x64
#IMPORTANT! For use on fresh install Ubuntu only!!

PG_USER_PASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`;
MAPFIG_DB_NAME=`< /dev/urandom tr -dc a-z | head -c${1:-14};echo;`;
MAPFIG_PG_PASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`;
MAPFIG_USER_PASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`;

#Check that apt is present
[ ! -x /usr/bin/apt-get ] && (echo "Error: Can't find apt."; exit 1)

RELEASE=`lsb_release -cs`

apt-get update

debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive

apt-get -y install wget tar gzip bzip2 zip unzip sudo postfix

##--------------------

#1. Install Apache
apt-get install -y apache2
if [ $? -ne 0 ]; then	echo "Error: APT failed"; 		exit 1;	fi
which apache2 2>&1 1>/dev/null
if [ $? -eq 1 ]; then	echo "Error: Can't find apt.";	exit 1;	fi
mkdir /var/www/html

#2. Install PostgreSQL
echo "deb http://apt.postgresql.org/pub/repos/apt/ $RELEASE-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-9.4 postgresql-client-9.4 postgresql-contrib-9.4
PG_VER=$(ls /usr/lib/postgresql/)
if [ ! -f /usr/lib/postgresql/${PG_VER}/bin/postgres ]; then
	echo "Error: Get PostgreSQL version"; exit 1;
fi

ln -sf /usr/lib/postgresql/${PG_VER}/bin/pg_config 	/usr/bin
ln -sf /var/lib/postgresql/${PG_VER}/main/		 	/var/lib/postgresql
ln -sf /var/lib/postgresql/${PG_VER}/backups		/var/lib/postgresql

#2.1 Create mapfig user/database
if [ $(sudo -u postgres 2>/dev/null psql -c "select usename from pg_user" | grep -m 1 -c mapfig) -eq 0 ]; then
	sudo -u postgres 2>/dev/null psql -c "create user mapfig with password '${MAPFIG_PG_PASS}';"
	if [ $? -eq 1 ]; then	echo "Error: Can't add mapfig user.";		exit 1;	fi
else
	sudo -u postgres 2>/dev/null psql -c "alter user mapfig with password '${MAPFIG_PG_PASS}';"
	if [ $? -eq 1 ]; then	echo "Error: Can't alter mapfig user.";		exit 1;	fi
fi

if [ $(sudo -u postgres 2>/dev/null psql -c "select datname from pg_database" | grep -m 1 -c mapfig) -eq 0 ]; then
	sudo -u postgres 2>/dev/null psql -c "create database ${MAPFIG_DB_NAME} owner=mapfig;"
	if [ $? -eq 1 ]; then	echo "Error: Can't add mapfig database.";	exit 1;	fi
fi

#2.2 Set PG user password
sudo -u postgres psql 2>/dev/null -c "alter user postgres with password '${PG_USER_PASS}'"
if [ $? -eq 1 ]; then	echo "Error: Can't set postgre user password.";		exit 1;	fi

#3. Instll GDAL and deps
apt-get install -y gdal-bin libgdal1h libgdal-dev
if [ $? -ne 0 ]; then	echo "Error: APT failed"; 		exit 1;	fi

#4. Add mapfig web user
if [ $(grep -m 1 -c mapfig /etc/passwd) -eq 0 ]; then
	useradd mapfig
fi
echo -e "${MAPFIG_USER_PASS}\n${MAPFIG_USER_PASS}" | passwd mapfig


#5. Install PHP
apt-get install -y php5 php5-dev php5-pgsql
if [ $? -ne 0 ]; then	echo "Error: APT failed"; 		exit 1;	fi
which php 2>&1 1>/dev/null
if [ $? -eq 1 ]; then	echo "Error: Can't find php.";	exit 1;	fi

a2enmod php5

#5.1 Enable short tags
sed -i.save 's/short_open_tag = Off/short_open_tag = On/p' /etc/php5/apache2/php.ini


#5.2 Install Mod Ruid
apt-get install -y libapache2-mod-ruid2
if [ $? -ne 0 ]; then	echo "Error: APT failed"; 		exit 1;	fi

a2enmod ruid2


#5.3 Add index and handlers
if [ $(sed -n '$p' /etc/apache2/apache2.conf | grep -m 1 -c 'AddType x-httpd-php .php .php3 .php4 .php5') -eq 0 ]; then
	echo 'DirectoryIndex index.html index.html.var index.php
AddType x-httpd-php .php .php3 .php4 .php5' >> /etc/apache2/conf.d/php.conf
fi

#6. Add VHOST, if it doesn't exist
VHOST_FILE='/etc/apache2/sites-enabled/000-default.conf'
if [ -L ${VHOST_FILE} ]; then
	rm ${VHOST_FILE}
	#6.1 Ask user for virtual host settigns (use mapfig-ubuntu-vhost-config-1.4.7.sh to re-run)
	echo "Enter the domain or sub domain for your MapFig Studio (${VHOST_FILE})."
	DEF_VHOST=$(hostname -f)
	read -p "Enter the domain or sub domain for your MapFig Studio [ ${DEF_MAIL_HOST} ]:" VHOST
	if [ -z "${VHOST}" ]; then	#if null
		VHOST=${DEF_VHOST}	#set current host as vhost
	fi

	read -p "Enter admin mail [ admin@${VHOST} ]" VHOST_MAIL
	if [ -z "${VHOST_MAIL}" ]; then	#if user entered empty
		VHOST_MAIL="admin@${VHOST_MAIL}"	#set default admin mail
	fi

	echo "<VirtualHost *:80>
    ServerAdmin ${VHOST_MAIL}
    DocumentRoot /var/www/html/
    ServerName ${VHOST}
    ErrorLog /var/log/apache2/maps.mydomain.com-error_log
    CustomLog /var/log/apache2/maps.mydomain.com-access_log common
    ### ruid ###
    RMode config
    RUidGid mapfig mapfig
    RGroups www-data
    AccessFileName .htaccess
    AddHandler x-httpd-php .php .php3 .php4 .php5
	<Directory /var/www/html/>
		Options Indexes FollowSymlinks
		AllowOverride All
		Order allow,deny
		Allow from all
	</Directory>
</VirtualHost>" > ${VHOST_FILE}
fi

#7. Download MapFig Studio via CDN
cd /var/www/html
rm /var/www/html/index.html
if [ ! -f MapFig-Studio.zip ]; then
	wget https://cdn.mapfig.com/MapFig-Studio/MapFig-Studio.zip
	if [ $? -ne 0 -o ! -f MapFig-Studio.zip ]; then
		echo 'Error: wget failed to download MapFig'; exit 1;
	fi
fi

which unzip 2>&1 1>/dev/null
if [ $? -eq 1 ]; then	apt-get install -y unzip;	fi

unzip -q MapFig-Studio.zip
if [ $? -ne 0 ]; then
	echo "Error: unzip failed"; 		exit 1;
else
	rm MapFig-Studio.zip
fi
mv /var/www/html/MapFig-Studio/* /var/www/html
rm -rf /var/www/html/MapFig-Studio/

#8. Grant Ownership of Installation Directory to Web User mapfig
chown -Rf mapfig:mapfig /var/www/html


#9. Update pg_hba to MD5 and set listen address
sed -i.save "s/.*listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/${PG_VER}/main/postgresql.conf
mv /etc/postgresql/${PG_VER}/main/pg_hba.conf /etc/postgresql/${PG_VER}/main/pg_hba.conf.orig
echo 'local all all md5
host all all 127.0.0.1 255.255.255.255 md5
host all all 0.0.0.0/0 md5
host all all ::1/128 md5' > /etc/postgresql/${PG_VER}/main/pg_hba.conf


#10. Prompt user for SMTP email information (mail_config.sh)
MAIL_CFG='/var/www/html/include/mail.config.php'

echo 'This script will configure Mapfig mail settings'
DEF_MAIL_HOST=$(hostname -f)
read -p "Enter your smtp email host (e.g. mail.domain.com) [ ${DEF_MAIL_HOST} ]:" MAIL_HOST
if [ -z "${MAIL_HOST}" ]; then	#if user entered empty
	MAIL_HOST=${DEF_MAIL_HOST}	#set current host as mail host
fi

read -p "Enter Email SSL Port: " MAIL_PORT
if [ -z "${MAIL_PORT}" ]; then	#if user entered empty
	MAIL_PORT=587
fi

read -p "Enter FULL Email Username [ verify@${MAIL_HOST#*.} ]" MAIL_USERNAME
if [ -z "${MAIL_USERNAME}" ]; then	#if user entered empty
	MAIL_USERNAME="verify@${MAIL_HOST}"	#set default username, verify
fi

read -p "Enter Email Password: " MAIL_PASSWORD
if [ -z "${MAIL_PASSWORD}" ]; then	#if user entered empty
	echo 'Error: No password entered!'; exit 1;
fi

#10.1 Update the mail configuration file
sed -i.save "s/define(\"MAIL_HOST\".*/define(\"MAIL_HOST\", \"${MAIL_HOST}\");/" "${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_USERNAME\".*/define(\"MAIL_USERNAME\", \"${MAIL_USERNAME}\");/" "${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_PASSWORD\".*/define(\"MAIL_PASSWORD\", \"${MAIL_PASSWORD}\");/" "${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_FROM\".*/define(\"MAIL_FROM\", \"${MAIL_USERNAME}\");/" "${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_PORT\".*/define(\"MAIL_PORT\", ${MAIL_PORT});/" "${MAIL_CFG}"


#11. Display Information for Installation
echo "INFO:
Virtual Host Configuration: ${VHOST_FILE}
Your mapfig postgresql database name is: ${MAPFIG_DB_NAME}
Your mapfig postgresql user password is: ${MAPFIG_PG_PASS}
Your mapfig os user password is: ${MAPFIG_USER_PASS}
Your postgres superuser password is: ${PG_USER_PASS}" | tee ${HOME}/mapfig-install.auth
echo "Password are saved in ${HOME}/mapfig-install.auth"

#12. Restart apache and postgresql for changes to take effect
service apache2 restart
service postgresql restart

exit 0;
