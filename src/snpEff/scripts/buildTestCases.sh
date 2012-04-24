#!/bin/sh

# Test cases hg37
./scripts/snpEffM.sh build -v -txt testCase

# Test cases hg37.61
./scripts/snpEffM.sh build -v -gtf22 testHg3761Chr15
./scripts/snpEffM.sh build -v -gtf22 testHg3761Chr16 

# Test cases hg37.63
./scripts/snpEffM.sh build -v -gtf22 testHg3763Chr1
./scripts/snpEffM.sh build -v -gtf22 testHg3763Chr20 
./scripts/snpEffM.sh build -v -gtf22 testHg3763ChrY 

# Test cases hg37.65
./scripts/snpEffM.sh build -v -gtf22 testHg3765Chr22
