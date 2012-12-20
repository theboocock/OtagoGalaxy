#!/bin/bash

echo "Moving:
submit_job.py
check_jobs.py
get_results.py
stop_job.py
nesi.py
config.py
universe_wsgi.ini
"

cp -f submit_job.py ../../../../lib/galaxy/jobs/runners/
cp -f check_jobs.py ../../../../lib/galaxy/jobs/runners/
cp -f get_results.py ../../../../lib/galaxy/jobs/runners/
cp -f stop_job.py ../../../../lib/galaxy/jobs/runners/
cp -f nesi.py ../../../../lib/galaxy/jobs/runners/
cp -f config.py ../../../../lib/galaxy/
cp -f universe_wsgi.ini ../../../../

