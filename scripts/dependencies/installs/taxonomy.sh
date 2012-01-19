#!/bin/bash
#
# Install taxonomy tools
#
# @Author James Boocock
#

wget https://bitbucket.org/natefoo/taxonomy/downloads/taxonomy_r3_linux2.6_i686.tar.gz
tar -xzf taxonomy_r3_linux2.6_i686.tar.gz
cd taxonomy_r3_linux2.6_i686
sudo mv t* /usr/bin
cd ..
rm -f taxonomy_r3_linux2.6_i686.tar.gz
rm -Rf taxonomy_r3_linux2.6_i686
