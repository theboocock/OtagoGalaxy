#!/bin/bash
#
# Edit these values to install in the correct directory
#
# Installs all the otago galaxy stuff
# 



#confiugrable preset needs to be set to your galaxy installation folder.
GALAXY_HOME_FOLDER=/home/sfk/scripts/galaxy-central/

#Current Location.
OTAGO_GALAXY_LOCATION=`pwd`

echo "Starting Otago Galaxy Install"
echo "Creating Otago Galaxy tools folder"
mkdir $GALAXY_HOME_FOLDER/tools/OtagoGalaxy
cp -v -R galaxy/ $GALAXY_HOME_FOLDER/tools/OtagoGalaxy/
echo "Installing Shared Jars"
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/composite_datatypes
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/jars/beagle
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/beagle
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/jars/vcf_to_csv
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/jars/presto
mkdir $GALAXY_HOME_FOLDER/tool-data/shared/ihs
echo "Installing snpEff"
cp -v src/snpEff/*.jar $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff/
cp -v src/snpEff/snpEff.config $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff/
echo "Installing Composite Datatypes"
cp -v src/composite_datatypes/*.py $GALAXY_HOME_FOLDER/tool-data/shared/composite_datatypes/
echo "Installing beagle"
cp -v src/beagle/*.jar          $GALAXY_HOME_FOLDER/tool-data/shared/jars/beagle/
cp -v src/beagle/bgl_to_ped     $GALAXY_HOME_FOLDER/tool-data/shared/beagle/
cp -v src/beagle/ped_to_ped     $GALAXY_HOME_FOLDER/tool-data/shared/beagle/
echo "Installing vcf to csv"
cp -v src/vcf_to_csv/*.jar      $GALAXY_HOME_FOLDER/tool-data/shared/jars/vcf_to_csv/
echo "Installing presto"
cp -v src/presto/presto.jar     $GALAXY_HOME_FOLDER/tool-data/shared/jars/presto/
echo "Installing Ihs"
cp -v src/iHS/ihs               $GALAXY_HOME_FOLDER/tool-data/shared/jars/ihs/
echo "Installing Otago Tools"
cp -v $OTAGO_GALAXY_LOCATION/scripts/tool_conf.xml $GALAXY_HOME_FOLDER
echo "Installing Otago Datatypes"
cp -v $OTAGO_GALAXY_LOCATION/scripts/datatypes_conf.xml $GALAXY_HOME_FOLDER
cp -v $OTAGO_GALAXY_LOCATION/datatypes/genetics.py $GALAXY_HOME_FOLDER/lib/galaxy/datatypes/
echo "Install Complete"





