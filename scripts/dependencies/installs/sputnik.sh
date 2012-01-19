#!/bin/bash
#
# Install SPUTNIK software for regional analysis
#
# @author James Boococok
#

wget https://bitbucket.org/natefoo/sputnik-mononucleotide/downloads/sputnik_r1_linux2.6_i686
sudo cp sputnik_r1_linux2.6_i686 /usr/bin/sputnik_r1_linux2
rm sputnik_r1_linux2
