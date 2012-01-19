#!/bin/bash
#
# @Author James Boocock
#
# Install weblogo3

wget http://weblogo.googlecode.com/files/weblogo-3.1.tar.gz
tar -xzf weblogo-3.1.tar.gz
cd weblogo-3.1
sudo python setup.py install
cd ..
rm weblogo-3.1.tar.gz
rm -Rf weblogo-3.1.tar.gz

