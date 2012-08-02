#!/bin/bash

echo Stopping Galaxy...
GALAXY_RUN_ALL=1 sh run.sh --stop-daemon
echo Done
