#!/bin/bash
#
# @Author James Boocock
#
# Install the tophat toolset
#

wget http://tophat.cbcb.umd.edu/downloads/tophat-1.4.0.tar.gz
tar -xzf tophat-1.4.0.tar.gz
cd tophat-1.4.0.tar.gz
sudo make
