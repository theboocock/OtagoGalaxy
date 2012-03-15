#!/bin/bash
#
# SETUP A SCRIPT FOR GALAXY INSTANCE
# THIS PRODUCTION SERVER IS SET TO RUN FOR 2 CORES THROUGH APACHE PROXY
#
# AUTHOR: JAMES BOOCOCK AND EDWARD HILLS
# DATE: 17/01/12

INSTALL_DIR=`pwd`

# Install galaxy dependencies
#
# http://wiki.g2.bx.psu.edu/Admin/Tools/Tool%20Dependencies
#
# DEPENDENCIES NOT INSTALLED
# - lps_tool
# - laj
# - gpass
# - gmaj
# - R leaps
# - addscores

#install python

sudo apt-get --force-yes install python
sudo apt-get --force-yes install python2.6
sudo apt-get --force-yes install python2.6-dev

#install repo that galaxy uses

sudo apt-get --force-yes install mercurial
#Installing R

sudo apt-get --force-yes install r-base
sudo apt-get --force-yes install r-base-dev
sudo apt-get --force-yes install git

#Installing Rpy

wget http://downloads.sourceforge.net/project/rpy/rpy2/2.2.x/rpy2-2.2.1.tar.gz
tar -xzf rpy2-2.2.1.tar.gz
cd rpy2-2.2.1
python setup.py install
cd $INSTALL_DIR
sudo rm -Rf rpy2-2.2.1
sudo rm -f rpy2-2.2.1.tar.gz
#Install beam2
sudo apt-get --force-yes install libgsl0-dev
wget http://stat.psu.edu/~yuzhang/software/beam2_source.tar
tar -xf beam2_source.tar
cp -f ../src/beam2/datastructure.h .
make
sudo mv BEAM2 /usr/bin
rm beam2_source.tar
rm *.o
rm *.h
rm *.cpp
rm makefile

#Install BWA

sudo apt-get --force-yes install bwa

#Install clustalw

sudo apt-get --force-yes install clustalw

#Install cufflinks

wget http://cufflinks.cbcb.umd.edu/downloads/cufflinks-1.3.0.Linux_x86_64.tar.gz
tar -xzf cufflinks-1.3.0.Linux_x86_64.tar.gz
cd cufflinks-1.3.0.Linux_x86_64
sudo mv cuff* /usr/bin
sudo mv gffread /usr/bin
sudo mv gtf_to_sam /usr/bin
cd $INSTALL_DIR
sudo rm -Rf cufflinks-1.3.0.Linux_x86_64
sudo rm -f cufflinks-1.3.0.Linux_x86_64.tar.gz

# Install python tables

sudo apt-get --force-yes install python-setuptools
sudo apt-get --force-yes install libnuma-dev
sudo apt-get --force-yes install python-dev
sudo apt-get --force-yes install liblzo2-dev
sudo apt-get --force-yes install subversion
sudo apt-get --force-yes install libhdf5-serial-dev
sudo apt-get --force-yes install libatlas-dev
sudo apt-get --force-yes install libatlas-base-dev
sudo easy_install -U numpy
sudo easy_install -U numexpr
sudo easy_install -U cython
sudo easy_install -U tables
sudo easy_install -U scipy
		
#GNUPLOT-py

sudo apt-get --force-yes install gnuplot
wget http://downloads.sourceforge.net/project/gnuplot-py/Gnuplot-py/1.8/gnuplot-py-1.8.tar.gz
tar -xzf gnuplot-py-1.8.tar.gz
cd gnuplot-py-1.8
sudo python setup.py install
cd $INSTALL_DIR
sudo rm -Rf gnuplot-py-1.8/
sudo rm -f gnuplot-py-1.8.tar.gz

#Install HyPhy

sudo apt-get --force-yes install cmake
git clone git://github.com/veg/hyphy.git
cd hyphy
cmake ./
sudo make install
cd $INSTALL_DIR
sudo rm -Rf hyphy

# INSTALL PASS2
wget http://stat.psu.edu/~yuzhang/software/pass2_source.tar
tar -xf pass2_source.tar
cp -f ../src/pass2/tilepass.cpp .
make
sudo mv pass2 /usr/bin
rm *.cpp
rm *.txt
rm *.o
rm makefile
rm pass2_source.tar
cd $INSTALL_DIR


# install lift over

wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.i386/liftOver
sudo mv liftOver /usr/bin

# install Perm with OpenMp

wget http://perm.googlecode.com/files/PerM_Linux32_v0.2.9.6.gz
gunzip PerM_Linux32_v0.2.9.6.gz
sudo mv PerM_Linux32_v0.2.9.6 /usr/bin/PerM

#Install EMBOSS

sudo apt-get --force-yes install emboss

#Install LASTZ

sudo apt-get --force-yes install last-align

#Install MEGABLAST

sudo apt-get --force-yes install blast2

#install samtools genomics suite
sudo apt-get --force-yes install samtools
# Install ghostscript

sudo apt-get --force-yes install ghostscript

# Install all dependencies in the dependencies folder

dependencies/installs/./*.sh

#create the galaxy user

sudo adduser galaxy

#install SSH

sudo apt-get --force-yes install openssh-client 

#Run tool install script

./tool_install.sh

# log into galaxy user

sudo su galaxy -c 'cd ~;  hg clone https://bitbucket.org/galaxy/galaxy-dist/;
wget http://bitbucket.org/ianb/virtualenv/raw/tip/virtualenv.py;
/usr/bin/python2.6 virtualenv.py --no-site-packages galaxy_env;
. ./galaxy_env/bin/activate;'

#Install SQL data base
sudo apt-get --force-yes install postgresql

#Create Galaxy database
sudo su postgres -c 'createdb galaxydb'

#Create galaxy database user
sudo su postgres -c 'createuser -SDR galaxy' 

# Run setup script for the postgres galaxy db.
# But this will also mean the passwords must be edited in the universe
# config files
sudo su postgres -c 'psql -f galaxysetup.sql'

# Install the webserver
sudo apt-get --force-yes install samtools

#enable required mods for galaxy

sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod xsend

#make log file for mod rewrite
sudo mkdir /etc/apache2/logs
sudo touch /etc/apache2/logs/rewrite_log

#Create the config file so apache will act as proxy for galaxy

sudo cp -f httpd.conf /etc/apache2/
sudo apt-get --force-yes install apache2

#Run apache Install script

./apache.sh

# Install TABIX

wget http://downloads.sourceforge.net/project/samtools/tabix/tabix-0.2.5.tar.bz2
bunzip2 tabix-0.2.5.tar.bz2
tar -xf tabix-0.2.5.tar
cd tabix-0.2.5
sudo make
sudo cp tabix /usr/bin/
sudo cp bgzip /usr/bin/
cd $INSTALL_DIR 
rm -Rf tabix-0.2.5
rm -Rf tabix-0.2.5.tar.bz2

#
# FTP SETUP 
#

#Install ftp server

sudo apt-get --force-yes install libssl-dev
sudo apt-get --force-yes install libpam0g-dev

#Setup galaxydb for ftp authentication

sudo su postgres -c 'createuser -SDR galaxyftp'
sudo su postgres -c 'psql -d galaxydb -f ftpsetup.sql'

#Get source for additional proftpd
sudo  apt-get --force-yes install libpq-dev
sudo mkdir /var/log/proftpd
sudo touch /var/log/proftpd/proftpd.log
wget ftp://ftp1.at.proftpd.org/ProFTPD/distrib/source/proftpd-1.3.4a.tar.gz
tar -xzf proftpd-1.3.4a.tar.gz
cd proftpd-1.3.4a
./configure --enable-openssl --with-opt-include=/usr/include/postgresql84/ --with-modules=mod_sql:mod_sql_postgres:mod_sql_passwd:mod_auth_pam
make
sudo make install
cd ..
rm -Rf proftpd-1.3.4a
rm -Rf proftpd-1.3.4a.tar.gz

#Copy proftpd config file
sudo cp -f $INSTALL_DIR/proftpd.conf /usr/local/etc/proftpd.conf
#Copy proftpd startup script
sudo cp -f $INSTALL_DIR/proftpd /etc/init.d/
#Restart proftpd 
sudo /etc/init.d/proftpd start

#install java

sudo apt-get install --force-yes openjdk-6-jre-headless
sudo apt-get install --force-yes openjdk-6-jdk
sudo apt-get install --force-yes mysql-server
#Run move scripts to install all our tools.

cd $INSTALL_DIR
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars
sudo mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes
$INSTALL_DIR/./move_files.sh
# Copy handy scripts to root directory

sudo cp -f restart_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f start_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f stop_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f start_webapp.sh /home/galaxy/galaxy-dist/

# Copy config files to root directory
sudo cp -f universe_wsgi.ini /home/galaxy/galaxy-dist/
sudo cp -f universe_wsgi.runner.ini /home/galaxy/galaxy-dist/
sudo cp -f universe_wsgi.webapp.ini /home/galaxy/galaxy-dist/

# Setup tool_conf.xml
#TODO James get tool_conf working

#Migrate data

source /home/galaxy/.bashrc
sudo echo "* * * * * chmod -R 777 /home/galaxy/galaxy-dist/database/ftp/*" | crontab


sudo su galaxy -c '/home/galaxy/galaxy-dist/./start_galaxy.sh'
sudo chown galaxy:galaxy /home/galaxy/galaxy-dist

echo Installation complete. Please go into /home/galaxy/galaxy-tools/universe.wsgi.ini and check the galaxy configuration.
