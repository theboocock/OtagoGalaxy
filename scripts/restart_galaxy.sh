#!/bin/bash

echo Restarting Galaxy...

./start_webapp.sh --stop-daemon
./start_webapp.sh --daemon

echo Done

