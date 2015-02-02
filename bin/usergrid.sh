#!/bin/bash -eux

while nc -q 1 ${CASS_HOST} ${CASS_PORT} < /dev/null; do sleep 10; echo "Awaiting cassandra"; done

cd /app
exec /sbin/setuser app java -javaagent:/app/lib/jamm.jar -cp ".:/app/etc" -jar /app/lib/usergrid-launcher.jar -nogui --port 8080