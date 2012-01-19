#!/bin/bash
#
# @Author James Boocock
#
# Install Rpackage leaps

wget http://cran.r-project.org/src/contrib/leaps_2.9.tar.gz
sudo R CMD INSTALL leaps_2.9.tar.gz
rm leaps_2.9.tar.gz
