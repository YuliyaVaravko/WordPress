#!/bin/bash

#Installing Apache
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
read -p "Enter Password for root: " rootpass
read -p "Enter DB name: " dbname
read -p "Enter user name: " dbuser
read -p "Enter password for $dbuser: " userpass

#Settings mysql_secure_installation
sudo cat > mysql_secure_installation.sql << EOF
# Make sure that NOBODY can access the server without a password
ALTER USER 'root'@'localhost' IDENTIFIED BY $rootpass;
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

sudo mysql -u root -p'$rootpass' <<MYSQL_SCRIPT
CREATE DATABASE $dbname;
CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Installing WordPress
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo rsync -av wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo rm /var/www/html/index.html

# wp-config.php
cd /home/user/wordpress/
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$dbname/" wp-config.php
sed -i "s/username_here/$dbuser/" wp-config.php
sed -i "s/password_here/$userpass/" wp-config.php
