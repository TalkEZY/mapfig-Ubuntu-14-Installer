#!/bin/bash -e
#Version: 0.3
#petiole installer
#tested with Ubuntu 14.0.4
#petiole.org, mapfig.com

PG_USER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
STUDIO_USER='mapfig'
STUDIO_DB_NAME=$(< /dev/urandom tr -dc a-z | head -c${1:-14})
STUDIO_PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
STUDIO_USER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})

#Get user input for mail configuration
echo 'This script will configure Petiole Studio mail settings'
DEF_MAIL_HOST=$(hostname -f)
read -p "Enter your smtp email host (e.g. mail.domain.com) [ ${DEF_MAIL_HOST} ]:" MAIL_HOST
if [ -z "${MAIL_HOST}" ]; then	#if user entered empty
	MAIL_HOST=${DEF_MAIL_HOST}	#set current host as mail host
fi
read -p "Enter Email SSL Port: " MAIL_PORT
read -p "Enter FULL Email Username [ verify@${MAIL_HOST} ]" MAIL_USERNAME
read -p "Enter Email Password: " MAIL_PASSWORD

#6.1 Ask user for virtual host settings (use mapfig-ubuntu-vhost-config-1.4.7.sh to re-run)
VHOST_FILE='/etc/apache2/sites-enabled/000-default.conf'
DEF_VHOST=$(hostname -f)
read -p "Enter the domain or sub domain for your Petiole Studio [ ${DEF_VHOST} ]:" VHOST
if [ -z "${VHOST}" ]; then	#if null
	VHOST=${DEF_VHOST}	#set current host as vhost
fi

read -p "Enter admin mail [ admin@${VHOST} ]" VHOST_MAIL
if [ -z "${VHOST_MAIL}" ]; then	#if user entered empty
	VHOST_MAIL="admin@${VHOST_MAIL}"	#set default admin mail
fi

#Check that apt is present
[ ! -x /usr/bin/apt-get ] && (echo "Error: Can't find apt."; exit 1)

RELEASE=$(lsb_release -cs)

debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y install wget tar gzip bzip2 zip unzip sudo postfix

#1. Install Apache
apt-get install -y apache2
mkdir -p /var/www/html

#2. Install PostgreSQL 9.4
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}-pgdg main" > /etc/apt/sources.list.d/pgdg.list
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

#2.1 Create studio user/database
#disable pg password temporarily
sed -i 's/local[ \t]\+all[ \t]\+all.*/local all all trust/'  /etc/postgresql/${PG_VER}/main/pg_hba.conf
service postgresql restart
if [ $(sudo -u postgres 2>/dev/null psql -c "select usename from pg_user" | grep -m 1 -c ${STUDIO_USER}) -eq 0 ]; then
	sudo -u postgres 2>/dev/null psql -c "create user ${STUDIO_USER} with password '${STUDIO_PG_PASS}';"
else
	sudo -u postgres 2>/dev/null psql -c "alter user ${STUDIO_USER} with password '${STUDIO_PG_PASS}';"
fi
#since db name is random, we don't need to check if it exists
sudo -u postgres 2>/dev/null psql -c "create database ${STUDIO_DB_NAME} owner=${STUDIO_USER}"
sudo -u postgres 2>/dev/null psql -c "create database ${STUDIO_DB_NAME}_stats owner=${STUDIO_USER}"


#2.2 Set PG user password
sudo -u postgres psql 2>/dev/null -c "alter user postgres with password '${PG_USER_PASS}'"

#3. Instll GDAL and deps
apt-get install -y gdal-bin libgdal1h libgdal-dev

#4. Add mapfig web user
if [ $(grep -m 1 -c ${STUDIO_USER} /etc/passwd) -eq 0 ]; then
	useradd -m ${STUDIO_USER}
fi
echo "${STUDIO_USER}:${STUDIO_USER_PASS}" | chpasswd


#5. Install PHP and Mod Ruid
apt-get install -y php5 php5-dev php5-pgsql libapache2-mod-ruid2
a2enmod php5 ruid2

#5.1 Enable short tags
sed -i.save 's/short_open_tag = Off/short_open_tag = On/p' /etc/php5/apache2/php.ini

#5.3 Add index and handlers
if [ $(grep -m 1 -c '^AddType x-httpd-php .php .php3 .php4 .php5' /etc/apache2/apache2.conf) -eq 0 ]; then
	cat >> /etc/apache2/conf-available/php.conf <<CMD_EOF
DirectoryIndex index.html index.html.var index.php
AddType x-httpd-php .php .php3 .php4 .php5
CMD_EOF
	ln -sf /etc/apache2/conf-available/php.conf /etc/apache2/conf-enabled/php.conf
fi

#6. Add VHOST, if it doesn't exist
if [ -L ${VHOST_FILE} ]; then
	rm ${VHOST_FILE}

	echo "<VirtualHost *:80>
    ServerAdmin ${VHOST_MAIL}
    DocumentRoot /var/www/html/
    ServerName ${VHOST}
    ErrorLog /var/log/apache2/maps.$(hostname)-error_log
    CustomLog /var/log/apache2/maps.$(hostname)-access_log common
    ### ruid ###
    RMode config
    RUidGid ${STUDIO_USER} ${STUDIO_USER}
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
cd /var/www/
rm -rf /var/www/html
if [ ! -f petiole.zip ]; then
	#wget change if you are downloading from another location
	wget https://cdn.acugis.com/petiole/v301/petiole.zip
fi

apt-get install -y unzip;

unzip -q petiole.zip
rm petiole.zip
mv /var/www/petiole /var/www/html

#8. Grant Ownership of Installation Directory to Web User mapfig
chown -Rf ${STUDIO_USER}:${STUDIO_USER} /var/www/html

#9. Update pg_hba to MD5 and set listen address
sed -i.save "s/.*listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/${PG_VER}/main/postgresql.conf
mv /etc/postgresql/${PG_VER}/main/pg_hba.conf /etc/postgresql/${PG_VER}/main/pg_hba.conf.orig
echo 'local all all md5
host all all 127.0.0.1 255.255.255.255 md5
host all all 0.0.0.0/0 md5
host all all ::1/128 md5' > /etc/postgresql/${PG_VER}/main/pg_hba.conf


#10. Prompt user for SMTP email information (mail_config.sh)
if [ -z "${MAIL_PORT}" ]; then	#if user entered empty
	MAIL_PORT=587
fi

if [ -z "${MAIL_USERNAME}" ]; then	#if user entered empty
	MAIL_USERNAME="verify@${MAIL_HOST}"	#set default username, verify
fi

if [ -z "${MAIL_PASSWORD}" ]; then	#if user entered empty
	echo 'Error: No password entered!'; exit 1;
fi

#10.1 Update the mail configuration file
MAIL_CFG='/var/www/html/include/mail.config.php'
sed -i.save "s/define(\"MAIL_HOST\".*/define(\"MAIL_HOST\", \"${MAIL_HOST}\");/" 				"${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_USERNAME\".*/define(\"MAIL_USERNAME\", \"${MAIL_USERNAME}\");/" 	"${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_PASSWORD\".*/define(\"MAIL_PASSWORD\", \"${MAIL_PASSWORD}\");/" 	"${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_FROM\".*/define(\"MAIL_FROM\", \"${MAIL_USERNAME}\");/" 			"${MAIL_CFG}"
sed -i.save "s/define(\"MAIL_PORT\".*/define(\"MAIL_PORT\", ${MAIL_PORT});/" 					"${MAIL_CFG}"


#11. Display Information for Installation
echo "INFO:
Virtual Host Configuration: ${VHOST_FILE}
Your studio database name is: ${STUDIO_DB_NAME}
Your studio stats database name is: ${STUDIO_DB_NAME}_stats
Your studio postgresql user password is: ${STUDIO_PG_PASS}
Your studio os user password is: ${STUDIO_USER_PASS}
Your postgres superuser password is: ${PG_USER_PASS}" | tee ${HOME}/studio-install.auth
echo "Password are saved in ${HOME}/studio-install.auth"

#12. Restart apache and postgresql for changes to take effect
service apache2 restart
service postgresql restart
