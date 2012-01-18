#!/bin/bash
#
# SETUP A SCRIPT FOR GALAXY INSTANCE
# THIS PRODUCTION SERVER IS SET TO RUN FOR 2 CORES THROUGH APACHE PROXY
#
# AUTHOR: JAMES BOOCOCK AND EDWARD HILLS
# DATE: 17/01/12

INSTALL_DIR=`pwd`

#install galaxy dependencies
#
#http://wiki.g2.bx.psu.edu/Admin/Tools/Tool%20Dependencies
#
#DEPENDENCIES NOT INSTALLED
# lps_tool
# laj
# gpass
# gmaj
# R leaps
# addscores
# 
#
#

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
sudo rm rpy2-2.2.1.tar.gz
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


#GNUPLOT-py

sudo apt-get --force-yes install gnuplot
sudo apt-get --force-yes install python-numpy
sudo apt-get --force-yes install python-scipy
wget http://downloads.sourceforge.net/project/gnuplot-py/Gnuplot-py/1.8/gnuplot-py-1.8.tar.gz
tar -xzf gnuplot-py-1.8.tar.gz
cd gnuplot-py-1.8
sudo python setup.py install
cd $INSTALL_DIR
/gpfs/apps/x86_64-rhel5/matlab/R2009b/toolbox/compiler/deploy/glnxa64/MCRInstaller.bin
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
mv -f ../src/pass2/tilepass.cpp .
make
sudo mv pass2 /usr/bin
rm *.cpp
rm *.txt
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

# Install ghostscript

sudo apt-get --force-yes install ghostscript

# Install python tables
# ------ NEEDS FIXING TODO -------
sudo apt-get --force-yes install python-setuptools

#   wget http://www.hdfgroup.org/ftp/HDF5/current/bin/linux/hdf5-1.8.8-linux-static.tar.gz
#   tar -xzf hdf5-1.8.8-linux-static.tar.gz
#   cd hdf5-1.8.8-linux.static
#   sudo mv bin/* /usr/bin/
#   sudo mv lib/* /usr/lib/
#   sudo mv share/* /usr/share/
#   sudo mv include/* /usr/include/
#   cd $INSTALL_DIR
#   Vsudo rm -Rf hdf5-1.8.8-linux.static

sudo apt-get --force-yes install python-dev
wget http://downloads.sourceforge.net/project/numpy/NumPy/1.6.1/numpy-1.6.1.tar.gz 

sudo apt-get install svn
tar -xzf numpy-1.6.1.tar.gz
cd numpy-1.6.1
sudo python setup.py install
cd $INSTALL_DIR
wget http://numexpr.googlecode.com/files/numexpr-2.0.tar.gz
tar -xzf numexpr-2.0.tar.gz
sudo python numexpr-2.0/setup.py install
rm -Rf numexpr-2.0/
sudo easy_install cython
#    sudo easy_install tables


#Install EMBOSS

sudo apt-get --force-yes install emboss

#Install LASTZ

sudo apt-get --force-yes install last-align

#Install MEGABLAST

sudo apt-get --force-yes install blast2

#install samtools genomics suite
sudo apt-get --force-yes install samtools
sudo apt-get --force-yes install blast2


#create the galaxy user

sudo adduser galaxy

#install SSH

sudo apt-get --force-yes install openssh-client 

# log into galaxy user

sudo su galaxy -c 'cd ~;  hg clone https://bitbucket.org/galaxy/galaxy-dist/;
wget http://bitbucket.org/ianb/virtualenv/raw/tip/virtualenv.py;
/usr/bin/python2.6 virtualenv.py --no-site-packages galaxy_env;
. ./galaxy_env/bin/activate;
echo "TEMP=/home/galaxy/galaxy-dist/database/tmp" >> .bashrc;
echo "export TEMP" >> .bashrc;'

#Install SQL data base
sudo apt-get --force-yes install postgresql

#Create Galaxy database
sudo su postgres -c 'createdb galaxydb'

#Create galaxy database user
sudo su postgres -c 'createuser -SDR galaxy' 

# Run setup script for the postgres galaxy db.
#

# But this will also mean the passwords must be edited in the universe
# config files

sudo su postgres -c 'psql -f galaxysetup.sql'
sudo cp -f proftpd.conf /etc/proftpd
# Install the webserver

sudo apt-get --force-yes install apache2
sudo apt-get --force-yes install samtools

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
udo easy_install cython

sudo /etc/init.d/apache2 restart

# Install TABIX


tar -xf tabix-0.2.5.tar.bz2
cd tabix-0.2.5
sudo make
sudo cp tabix /usr/bin/
sudo cp bgzip /usr/bin/
cd ..
rm -Rf tabix-0.2.5

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
wget ftp://ftp1.at.proftpd.org/ProFTPD/distrib/source/proftpd-1.3.4a.tar.gz
tar -xzf proftpd-1.3.4a.tar.gz
cd proftpd-1.3.4a
./configure --enable-openssl --with-opt-include=/usr/include/postgresql84/ --with-modules=mod_sql:mod_sql_postgres:mod_sql_passwd:mod_auth_pam
make
sudo make install
cd ..
rm -Rf proftpd-1.3.4a

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

sudo echo "* * * * * chmod -R 777 /home/galaxy/galaxy-dist/database/ftp/*" | crontab

sudo /home/galaxy/galaxy-dist/./manage_db.sh upgrade

# Setup BioPerl
echo Downloading ensembl cache, ~1.8gb...
wget ftp://ftp.ensembl.org/pub/release-65/variation/VEP/homo_sapiens/homo_sapiens_vep_65_sift_polyphen.tar.gz

tar -xzf homo_sapiens_vep_65_sift_polyphen.tar.gz
mv homo_sapiens ../src/ensembl_cache/
rm -f homo_sapiens_vep_65_sift_polyphen.tar.gz

sudo cp -fR ../src/bioperl-live /usr/local/
sudo cp -fR ../src/ensembl /usr/local/
sudo cp -fR ../src/ensembl-compara /usr/local/
sudo cp -fR ../src/ensembl-variation /usr/local/
sudo cp -fR ../src/ensembl-functgenomics /usr/local/

echo "PERL5LIB=${PERL5LIB}:/usr/local/bioperl-live" >> /home/galaxy/.bashrc
echo "PERL5LIB=${PERL5LIB}:/usr/local/ensembl/modules" >> /home/galaxy/.bashrc 
echo "PERL5LIB=${PERL5LIB}:/usr/local/ensembl-compara/modules" >> /home/galaxy/.bashrc
echo "PERL5LIB=${PERL5LIB}:/usr/local/ensembl-variation/modules" >> /home/galaxy/.bashrc
echo "PERL5LIB=${PERL5LIB}:/usr/local/ensembl-functgenomics/modules" >> /home/galaxy/.bashrc
echo "PERL5LIB=${PERL5LIB}:/home/galaxy/galaxy-dist/tool-data/shared/vcfperltools" >> /home/galaxy/.bashrc
echo "export PERL5LIB" >> /home/galaxy/.bashrc
source /home/galaxy/.bashrc


sudo chown -R galaxy:galaxy /home/galaxy/galaxy-dist
echo Installation complete. Please go into /home/galaxy/galaxy-tools/universe.wsgi.ini and change the ftp_upload_name to reflect your domain name.
