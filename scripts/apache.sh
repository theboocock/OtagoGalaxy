#!/bin/bash
# 
# Install Script for apache install
#

#enable required mods for galaxy

sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer


curl -O 'https://tn123.org/mod_xsendfile/mod_xsendfile.c' -o mod_xsendfile.c
sudo apt-get --force-yes install apache2-prefork-dev 
mv mod_xsendfile* mod_xsendfile.c
sudo apxs2 -cia mod_xsendfile.c

sudo rm -Rf .libs/
sudo rm -f mod_xsendfile.*

#make log file for mod rewrite
sudo mkdir /etc/apache2/logs
sudo touch /etc/apache2/logs/rewrite_log

#Create the config file so apache will act as proxy for galaxy

sudo cp -f httpd.conf /etc/apache2/

#Restart Apache

sudo /etc/init.d/apache2 restart
