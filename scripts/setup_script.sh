#SETUP A SCRIPT FOR GALAXY INSTANCE
#THIS PRODUCTION SERVER IS SET TO RUN FOR 2 CORES THROUGH APACHE PROXy
# AUTHOR JAMES BOOCOCK

#install python

INSTALL_DIR=`pwd`

sudo apt-get install python

#install repo that galaxy uses

sudo apt-get install mercurial

#create the galaxy user

sudo adduser galaxy

#install SSH

sudo apt-get install openssh-client 

# log into galaxy user

sudo su galaxy -c 'cd ~;  hg clone https://bitbucket.org/galaxy/galaxy-dist/;
wget http://bitbucket.org/ianb/virtualenv/raw/tip/virtualenv.py;
/usr/bin/python2.6 virtualenv.py --no-site-packages galaxy_env;
. ./galaxy_env/bin/activate;
echo "TEMP=/home/galaxy/galaxy-dist/database/tmp" >> .bashrc;
echo "export TEMP" >> .bashrc;'

#Install SQL data base
sudo apt-get install postgresql

#Create Galaxy database
sudo su postgres -c 'createdb galaxydb'

#Create galaxy database user
sudo su postgres -c 'createuser -SDR galaxy' 

# Run setup script for the postgres galaxy db.
#
# You can change the default passwords by editing galaxysetup.sql
# But this will also mean the passwords must be edited in the universe
# config files

sudo su postgres -c 'psql -f galaxysetup.sql'
sudo cp -f proftpd.conf /etc/proftpd
# Install the webserver

sudo apt-get install apache2
sudo apt-get install samtools

#enable required mods for galaxy

sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer

#make log file for mod rewrite
sudo mkdir /etc/apache2/logs
sudo touch /etc/apache2/logs/rewrite_log

#Create the config file so apache will act as proxy for galaxy

sudo cp -f httpd.conf /etc/apache2/

#Restart Apache

sudo /etc/init.d/apache2 restart

# Install TABIX

sudo wget http://downloads.sourceforge.net/project/samtools/tabix/tabix-0.2.5.tar.bz2
tar -xf tabix-0.2.5.tar.bz2
cd tabix-0.2.5
sudo make
sudo cp tabix /usr/bin/
sudo cp bgzip /usr/bin/
cd ..

#
# FTP SETUP 
#

#Install ftp server

sudo apt-get install libssl-dev
sudo apt-get install libpam0g-dev

#Setup galaxydb for ftp authentication

sudo su postgres -c 'createuser -SDR galaxyftp'
sudo su postgres -c 'psql -d galaxydb -f ftpsetup.sql'

#Get source for additional proftpd
sudo  apt-get install libpq-dev
wget ftp://ftp1.at.proftpd.org/ProFTPD/distrib/source/proftpd-1.3.4a.tar.gz
tar -xf proftpd-1.3.4a.tar.gz
cd proftpd-1.3.4a
./configure --enable-openssl --with-opt-include=/usr/include/postgresql84/ --with-modules=mod_sql:mod_sql_postgres:mod_sql_passwd:mod_auth_pam
make
sudo make install


#Copy proftpd config file


sudo cp -f $INSTALL_DIR/proftpd.conf /usr/local/etc/proftpd.conf

#Copy proftpd startup script

sudo cp -f $INSTALL_DIR/proftpd /etc/init.d/

#Restart proftpd 

sudo /etc/init.d/proftpd start

#Run move scripts to install all our tools.
cd $INSTALL_DIR
sudo mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes
$INSTALL_DIR/./move_files.sh

#Migrate data

sudo chown -R galaxy:galaxy /home/galaxy/galaxy-dist
sudo echo "* * * * * chmod -R 777 /home/galaxy/galaxy-dist/database/ftp/*" | crontab

sudo /home/galaxy/galaxy-dist/./manage_db.sh upgrade












 

