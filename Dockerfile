FROM phusion/baseimage:0.9.16
MAINTAINER Neil Ellis hello@neilellis.me
EXPOSE 80
EXPOSE 9160

CMD ["/sbin/my_init"]

ENV HOME /root
WORKDIR /root

RUN adduser --disabled-password --gecos '' app


############################### END OF INITIAL ################################


# Setup Apt-Get
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list   && \
    echo "deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse" >> /etc/apt/sources.list  && \
    echo "deb http://archive.ubuntu.com/ubuntu trusty-security multiverse" >> /etc/apt/sources.list && \
    curl -sL https://deb.nodesource.com/setup | sudo bash - && \
    sed -i.bak 's/main$/main universe/' /etc/apt/sources.list && \
    add-apt-repository -y ppa:webupd8team/java  && \
    add-apt-repository -y ppa:nginx/stable

# Install Base Packages
RUN apt-get update -q &&  apt-get install -q -y pwgen ca-certificates   \
    wget curl   dbus libdbus-glib-1-2  bzip2  nodejs git  dnsutils \
    python-dev libssl-dev  gcc build-essential  gettext --no-install-recommends


############################### END OF PRE-REQS ###############################



# Java
ENV JAVA_VERSION 7
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-oracle

RUN rm -rf /var/cache/oracle-jdk${JAVA_VERSION}-installer && \
    echo "JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-oracle" >> /etc/environment && \
    echo oracle-java${JAVA_VERSION}-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections

# Misc
RUN apt-get update -q &&  apt-get install -q -y oracle-java${JAVA_VERSION}-installer maven nginx --no-install-recommends


RUN  ln -s /home/app /app

RUN npm install -g npm@2.1.1 && \
    npm cache clear  && \
    npm install -g  npm-check-updates npm-install-missing pm2


ENV CASSANDRA_VERSION 2.1.2
# Cassandra
RUN wget http://mirror.ox.ac.uk/sites/rsync.apache.org/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz && \
    tar -xvzf apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz && \
    mv apache-cassandra-${CASSANDRA_VERSION} /app/cassandra

############################### END OF APPS ###################################

# Clean
RUN apt-get autoremove -y && \
    apt-get clean all && \
    rm -rf /tmp/* /var/lib/apt/lists/*  /var/www

############################### END OF INSTALLS ###############################



# Prep directory structure
VOLUME /home/app/var
VOLUME /home/app/cassandra/data

RUN mkdir /home/app/log   && mkdir /home/app/tmp
RUN chown -R app:app  /home/app  && chown -h app:app /app /home/app/var
RUN ln -s /var/log/cassandra /home/app/log/cassandra

USER app
ENV HOME /home/app
WORKDIR /home/app

# Build server
ENV USERGRID_BRANCH neilellis-branch
RUN git clone https://github.com/neilellis/incubator-usergrid.git /home/app/usergrid  && echo
RUN cd /home/app/usergrid && git checkout ${USERGRID_BRANCH}
#RUN cd /home/app/usergrid && mv /home/app/usergrid/stack /home/app
#RUN cd /app/stack && mvn -q -DskipTests=true -Dproject.build.sourceEncoding="UTF-8"  clean install



# Used to cache dependencies in case of spurious build failure
#RUN cd /home/app/usergrid/stack && mvn dependency:resolve

# Now build
RUN cd /home/app/usergrid/stack && mvn clean install -q -T 0.5C -DskipIntegrationTests  -DskipTests

RUN mv /home/app/usergrid/portal /home/app
RUN cd /home/app/portal && chmod u+x /home/app/portal/build.sh  && npm-install-missing
COPY  etc/config.js /tmp/config.js
RUN envsubst < /tmp/config.js > /home/app/portal/config.js
RUN cd /home/app/portal && ./build.sh
RUN tar -xvf /home/app/portal/dist/usergrid-portal.tar && mv usergrid-portal* /home/app/public  && mkdir /home/app/downloads

RUN cd /home/app/usergrid/sdks && mv html5-javascript usergrid-web-js && tar -zcvf /home/app/downloads/usergrid-web-js.tgz usergrid-web-js
#RUN cd /home/app/usergrid/sdks/java && mvn clean install -q -T 0.5C -DskipIntegrationTests  -DskipTests && mv target/usergrid-java-client-*.jar /home/app/downloads/usergrid-java.jar
RUN rm  /home/app/usergrid/stack/launcher/target/usergrid-launcher-*tests.jar
RUN mkdir /app/lib && mv /home/app/usergrid/stack/launcher/target/usergrid-launcher-*.jar /app/lib/usergrid-launcher.jar
RUN cd /app/lib && curl http://central.maven.org/maven2/com/github/jbellis/jamm/0.3.0/jamm-0.3.0.jar > jamm.jar
COPY bin/ /app/bin/
COPY etc/ /app/etc/

USER root
RUN chown app:app /app/bin/* && chmod 755 /app/bin/*

# Prepare rinit processes
RUN mkdir /etc/service/usergrid  /etc/service/nginx /etc/service/cassandra

RUN cp /app/etc/nginx.conf /etc/nginx/nginx.conf && \
    cp /app/bin/init.sh //etc/my_init.d/99_usergrid_init.sh && \
    cp /app/bin/nginx.sh /etc/service/nginx/run && \
    cp /app/bin/cassandra.sh /etc/service/cassandra/run && \
    cp /app/bin/usergrid.sh /etc/service/usergrid/run


RUN chmod 755  /etc/service/usergrid/run  /etc/service/nginx/run  /etc/service/cassandra/run

# Clean up
RUN rm -rf /app/portal && rm -rf /app/usergrid


ENV ADMIN_EMAIL auto
ENV ADMIN_PASSWORD admin
ENV USERGRID_URL auto
ENV MAIL_HOST auto
ENV MAIL_PORT 465
ENV MAIL_USER admin
ENV MAIL_PASSWORD ${ADMIN_PASSWORD}
ENV CASS_HOST localhost
ENV CASS_PORT 9160
ENV BACKUP_SECRET auto


############################### END OF BUILD ##################################
