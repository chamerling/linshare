# chamerling/linshare
#
# VERSION               1.0

FROM ubuntu:latest
MAINTAINER Christophe Hamerling "chamerling@linagora.com"

# Install packages

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties
#RUN add-apt-repository ppa:webupd8team/java -y
#RUN apt-get update
#RUN echo "oracle-java7-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN apt-get install -y zip wget curl build-essential postgresql 
#RUN apt-get oracle-java7-installer

# Create files and folders
# ENV JAVA_HOME /usr/lib/jvm/java-7-oracle/jre/

RUN apt-get install -y tomcat6

RUN mkdir -p /tmp/linshare_war
RUN mkdir -p /var/lib/linshare
RUN mkdir -p /etc/linshare
RUN mkdir -p /var/lib/linshare/repository
RUN chown tomcat6 /var/lib/linshare/repository

RUN curl -o /tmp/linshare_war/linshare.war https://forge.linshare.org/attachments/download/300/linshare-1.4.4-without-SSO.war
RUN unzip /tmp/linshare_war/linshare.war -d /tmp/linshare_war
RUN cp /tmp/linshare_war/WEB-INF/classes/linshare.properties.sample /etc/linshare/linshare.properties
RUN cp /tmp/linshare_war/WEB-INF/classes/log4j.properties /etc/linshare/log4j.properties

# ADD resources/linshare.properties /tmp/
# ADD resources/tomcat6 etc/default/

# Database

# RUN psql...
RUN echo "local    linshare,linshare_data    linshare        md5" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "host     linshare,linshare_data    linshare    127.0.0.1/32    md5" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "host     linshare,linshare_data    linshare    ::1/128    md5" >> /etc/postgresql/9.1/main/pg_hba.conf

RUN locale-gen en_US.UTF-8
RUN useradd linshare

RUN service postgresql restart

ADD resources/user.sql /tmp/
ADD resources/init.sql /tmp/

RUN su - postgres -c 'psql < /tmp/user.sql'
RUN su - postgres -c 'psql < /tmp/init.sql'

RUN su - linshare -c 'psql -d linshare < /tmp/linshare_war/WEB-INF/classes/sql/postgresql/createSchema.sql'
RUN su - linshare -c 'psql -d linshare < /tmp/linshare_war/WEB-INF/classes/sql/postgresql/import-postgresql.sql'

RUN service tomcat6 stop
RUN echo "JAVA_OPTS=\"\${JAVA_OPTS} -Dlinshare.config.path=file:/etc/linshare -Dlog4j.configuration=file:/etc/linshare/log4j.properties\"" >> /etc/default/tomcat6

RUN cp /tmp/linshare_war/linshare.war /var/lib/tomcat6/webapps/
RUN service tomcat6 restart

# Expose public and admin ports
EXPOSE 8080 5432

ADD resources/start.sh /
RUN chmod +x /start.sh
CMD ["/start.sh"]