#!/bin/bash

echo "Creating soft symlinks for converters"

echo "VCF converters.."

ln -fs ~/galaxy-dist/tools/SOER1000genes/galaxy/vcf_to_tped/vcf_to_tped.xml ~/galaxy-dist/lib/galaxy/datatypes/converters/
ln -fs ~/galaxy-dist/tools/SOER1000genes/galaxy/vcf_to_csv/vcf_to_csv.xml ~/galaxy-dist/lib/galaxy/datatypes/converters/
ln -fs ~/galaxy-dist/tools/SOER1000genes/galaxy/beagle/vcf_to_beagle.xml ~/galaxy-dist/lib/galaxy/datatypes/converters/
ln -fs ~/galaxy-dist/tools/SOER1000genes/galaxy/beagle/vcf_to_beagle.sh ~/galaxy-dist/lib/galaxy/datatypes/converters/
ln -fs ~/galaxy-dist/tools/SOER1000genes/galaxy/vcf_to_ped/vcf_to_ped.xml ~/galaxy-dist/lib/galaxy/datatypes/converters/

echo -e "\nDone!"
