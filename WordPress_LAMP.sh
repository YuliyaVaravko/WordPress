#!/bin/bash

#Installing Apache
sudo apt update -y
sudo apt install -y apache2 apache2-utils
sudo systemctl enable apache2
sudo systemctl start apache2
sudo a2enmod rewrite
sudo systemctl restart apache2

#Installing PHP
sudo apt install -y php7.4 php7.4-mysql libapache2-mod-php7.4 php7.4-cli php7.4-cgi php7.4-gd

#Installing  MariaDB
sudo apt install -y mariadb-client mariadb-server
# Variables for MariaDB
if !(which  pwgen); then
sudo apt install  -y pwgen
fi
DB_NAME=wordpress
DB_USER=wp_user
DB_ROOT_PASS=$(pwgen 10)
DB_USER_PASS=$(pwgen 10)
#DB_ROOT_PASS=$(openssl rand -base64 32)
#DB_USER_PASS=$(openssl rand -base64 32)


#Settings mysql_secure_installation
sudo cat > mysql_secure_installation.sql << EOF
# Make sure that NOBODY can access the server without a password
ALTER USER 'root'@'localhost' IDENTIFIED BY $DB_ROOT_PASS;
# Kill the anonymous users
DELETE FROM mysql.user WHERE User='';
# disallow remote login for root
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
# Kill off the demo database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
# Make our changes take effect
FLUSH PRIVILEGES;
EOF

sudo systemctl enable mariadb
sudo systemctl start mariadb

sudo mysql -u root -p'$DB_ROOT_PASS' <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Installing WordPress
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
if !(which  rsync); then
sudo apt install  -y rsync
fi
sudo rsync -av wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo rm /var/www/html/index.html

# wp-config.php
cd /home/user/wordpress/
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_USER_PASS/" wp-config.php

echo WordPress has been installed successfully
echo You can find data base connection details below:
echo -data base name is $DB_NAME
echo -data base user is $DB_USER
echo -user password is $DB_USER_PASS
echo -root password is $DB_ROOT_PASS
