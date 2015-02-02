#!/bin/bash -eu
myip=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
myhostdig=$(dig +short -x $myip)
myhost=${myhostdig::-1}



if [[ $USERGRID_URL == "auto" ]]
then
    export USERGRID_URL="http://${myhost}"
fi

if [[ $ADMIN_EMAIL == "auto" ]]
then
    export ADMIN_EMAIL="info@${myhost}"
fi

if [[ $MAIL_HOST == "auto" ]]
then
    export MAIL_HOST="${myhost}"
fi

if [[ $BACKUP_SECRET == "auto" ]]
then
    pwgen 24 > /app/etc/backup.pwd.txt
else
    echo $BACKUP_SECRET > /app/etc/backup.pwd.txt
fi


cp /app/bin/backup.sh  /etc/cron.hourly

echo "********"
echo "******** Backups will be encoded with secret: $(/root/backup.pwd.txt)"
echo "********"

export CASS_URL="${CASS_HOST}:${CASS_PORT}"
envsubst '$ADMIN_EMAIL:$ADMIN_PASSWORD:$USERGRID_URL:$MAIL_USER:$MAIL_PASSWORD:$MAIL_HOST:$MAIL_PORT' < /app/etc/usergrid.template.properties > /app/etc/usergrid.properties
cat /app/etc/usergrid.properties
