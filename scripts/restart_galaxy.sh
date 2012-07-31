#!/bin/bash

echo Restarting Galaxy...
./stop_galaxy.sh
./start_galaxy.sh
echo Done

