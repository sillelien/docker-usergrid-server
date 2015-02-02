Usergrid Launcher Docker image
==============================


Please see http://usergrid.incubator.apache.org/ for more information on Usergrid.

This project was originally based on https://github.com/johnament/usergrid-launcher-docker however this image is based on the phusion/baseimage and uses rinit to keep processes running. It is an all in one image that includes cassandra and the portal.

The application runs behind an NginX instance and exposes port 80 for Usergrid access and port 9160 for access to the cassandra instance. It also exposes the cassandra data directory as a volume (useful in PaaS type environments):

```dockerfile
VOLUME /var/lib/cassandra
```

For security the application is run under the 'app' user, not as root.

The following environment variables should also be set at runtime:

ADMIN_EMAIL (me@example.com) - the email address for the admin user
ADMIN_PASSWORD (admin) - the password for the admin user
USERGRID_URL (http://localhost:8080/) - the address of this usergrid instance when deployed
HOST (mail.example.com) - the mail server (SMTPS protocol).
MAIL_PORT (123) - the port of the mail server
MAIL_USER ("") - the username for the mail server
MAIL_PASSWORD ("") - the password for the mail server
CASS_URL (localhost:9160) - do not change at this stage


To start Usergrid simply run

`docker run -p 8080:80 -p 9160:9160 -dit neilellis/usergrid-launcher-docker

This will expose port 80 on the VM, 9160 on the VM locally so that you can connect over HTTP and to Cassandra.

After the image is up, you'll need to do the standard setup steps.  [Run Usergrid Database & Super User Setup](http://usergrid.readthedocs.org/en/latest/deploy-local.html#run-usergrid-database-super-user-setup).

Username = admin Password = admin (unless you changed the value of ADMIN_PASSWORD.

After the system is setup, you can access the portal by going to http://localhost:8080, you should replace `8080` if your port is different and `localhost` if your docker server is running somewhere else (e.g. boot2docker)


If you visit http://localhost:8080/downloads you will see a list of clients that can be downloaded for this version of Usergrid.
