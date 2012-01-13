cd `dirname $0`
echo $1
for i in {0..1}; do
    python ./scripts/paster.py serve universe_wsgi.webapp.ini ${1} --server-name=web$i --pid-file=web$i.pid --log-file=web$i.log $@
done
python ./scripts/paster.py serve universe_wsgi.runner.ini ${1} --server-name=runner0 --pid-file=runner0.pid --log-file=runner0.log $@
