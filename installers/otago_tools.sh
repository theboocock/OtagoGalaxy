#!/bin/bash
#
# Edit these values to install in the correct directory
#
# Installs all the otago galaxy stuff
# 

GALAXY_HOME_FOLDER=~/new_galaxy/galaxy-central

getoptions(){
    while getopts "nd" opt; do
    case $opt in
    n)
    INSTALL_TOOL_CONF="TRUE"
    ;;
    d)
    INSTALL_OTAGO_DATATYPES="TRUE"
    ;;
    ?)
    exit 1
    ;;
    esac
done
}

getoptions "$@"

#confiugrable preset needs to be set to your galaxy installation folder.

#Current Location.
OTAGO_GALAXY_LOCATION=`pwd`

echo "Starting Otago Galaxy Install"
echo "Creating Otago Galaxy tools folder"
mkdir -p $GALAXY_HOME_FOLDER/tools/OtagoGalaxy
cp   -R galaxy/ $GALAXY_HOME_FOLDER/tools/OtagoGalaxy/
echo "Installing Shared Jars"
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff/data
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/composite_datatypes
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/jars/beagle
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/beagle
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/jars/vcf_to_csv
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/jars/presto
mkdir -p $GALAXY_HOME_FOLDER/tool-data/shared/ihs

echo "Installing snpEff"
cp src/snpEff/*.jar $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff/
#cp src/snpEff/snpEff.config $GALAXY_HOME_FOLDER/tool-data/shared/jars/snpEff/
echo "Installing Composite Datatypes"
cp src/composite_datatypes/*.py $GALAXY_HOME_FOLDER/tool-data/shared/composite_datatypes/
echo "Installing beagle"
cp src/beagle/*.jar          $GALAXY_HOME_FOLDER/tool-data/shared/jars/beagle/
cp src/beagle/bgl_to_ped     $GALAXY_HOME_FOLDER/tool-data/shared/beagle/
cp src/beagle/ped_to_bgl    $GALAXY_HOME_FOLDER/tool-data/shared/beagle/
echo "Installing vcf to csv"
cp src/vcf_to_csv/*.jar      $GALAXY_HOME_FOLDER/tool-data/shared/jars/vcf_to_csv/
echo "Installing presto"
cp src/presto/presto.jar     $GALAXY_HOME_FOLDER/tool-data/shared/jars/presto/
echo "Installing Ihs"
cp src/iHS/ihs               $GALAXY_HOME_FOLDER/tool-data/shared//ihs/
if [ "$INSTALL_TOOL_CONF" == "" ]; then
    echo "Installing Otago Tool configuration"
    cp $OTAGO_GALAXY_LOCATION/scripts/tool_conf.xml $GALAXY_HOME_FOLDER
else
    echo "Did not install the tool_conf the tools will have to be added manually \
          tool_conf.xml is located in the scripts folder"
fi
if [ "$INSTALL_OTAGO_DATATYPES" == "" ]; then
    echo "Installing Otago Datatypes"
    cp $OTAGO_GALAXY_LOCATION/datatypes/datatypes_conf.xml $GALAXY_HOME_FOLDER
    cp  $OTAGO_GALAXY_LOCATION/datatypes/genetics.py $GALAXY_HOME_FOLDER/lib/galaxy/datatypes/
    cp $OTAGO_GALAXY_LOCATION/datatypes/impute.py $GALAXY_HOME_FOLDER/lib/galaxy/datatypes
    cp $OTAGO_GALAXY_LOCATION/datatypes/registry.py $GALAXY_HOME_FOLDER/lib/galaxy/datatypes
else
    echo "Did not install the Otago datatypes the tools will have to be added manually \
          relevant files are located in the datatypes directory"
    
fi
echo "Further setup required, please open ${GALAXY_HOME_FOLDER}/tool-data/shared/jars/snpEff/snpEff.config
and change the data directory to ${GALAXY_HOME_FOLDER}/tool-data/shared/jars/snpEff/data"

echo "Install Complete"





