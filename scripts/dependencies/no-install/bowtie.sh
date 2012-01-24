#!/bin/bash
#
#Install the bowtie galaxy dependencies
#
#@author James Boocock
#

wget http://downloads.sourceforge.net/project/bowtie-bio/bowtie/0.12.7/bowtie-0.12.7-linux-i386.zip
unzip  bowtie-0.12.7-linux-i386.zip
cd bowtie-0.12.7
sudo cp bowtie* /usr/bin
cd ..
sudo rm bowtie-0.12.7-linux-i386.zip
sudo rm -Rf bowtie-0.12.7/
