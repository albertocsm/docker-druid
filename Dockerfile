FROM bikeemotion/ubuntu	
MAINTAINER bikeemotion

# Add Java 7 repository
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:webupd8team/java
RUN apt-get update

# Oracle Java 7
RUN echo oracle-java-7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java7-installer
RUN apt-get install -y oracle-java7-set-default

# MySQL (Metadata store)
RUN apt-get install -y mysql-server

# Supervisor
RUN apt-get install -y supervisor

# Maven
RUN wget -q -O - http://www.us.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz | tar -xzf - -C /usr/local
RUN ln -s /usr/local/apache-maven-3.2.5 /usr/local/apache-maven
RUN ln -s /usr/local/apache-maven/bin/mvn /usr/local/bin/mvn

# Zookeeper
RUN wget -q -O - http://www.us.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar -xzf - -C /usr/local
RUN cp /usr/local/zookeeper-3.4.6/conf/zoo_sample.cfg /usr/local/zookeeper-3.4.6/conf/zoo.cfg
RUN ln -s /usr/local/zookeeper-3.4.6 /usr/local/zookeeper

# git
RUN apt-get install -y git

# Druid system user
RUN adduser --system --group --no-create-home druid
RUN mkdir -p /var/lib/druid
RUN chown druid:druid /var/lib/druid

# Pre-cache Druid dependencies
RUN mvn dependency:get -DremoteRepositories=https://metamx.artifactoryonline.com/metamx/pub-libs-releases-local -Dartifact=io.druid:druid-services:0.6.171 -Dartifact=io.druid.extensions:druid-examples:0.6.171

# Druid (release tarball)
ENV DRUID_VERSION 0.6.171
RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-services-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /usr/local
RUN ln -s /usr/local/druid-services-$DRUID_VERSION /usr/local/druid

#WORKDIR /usr/local/druid

#RUN java "-Ddruid.extensions.coordinates=[\"io.druid.extensions:druid-s3-extensions\", \"io.druid.extensions:mysql-metadata-storage\", \"io.druid.extensions:druid-examples\"]" -Ddruid.extensions.localRepository=/usr/local/druid/repository -Ddruid.extensions.remoteRepositories=[\"file:///root/.m2/repository/\",\"http://repo1.maven.org/maven2/\",\"https://metamx.artifactoryonline.com/metamx/pub-libs-releases-local\"] -cp /usr/local/druid/lib/* io.druid.cli.Main tools pull-deps

WORKDIR /

# Setup metadata store
RUN /etc/init.d/mysql start && echo "GRANT ALL ON druid.* TO 'druid'@'localhost' IDENTIFIED BY 'diurd'; CREATE database druid CHARACTER SET utf8;" | mysql -u root && /etc/init.d/mysql stop

#Add firehose spec and data
ADD spec_file.spec /usr/local/druid/spec_file.spec
ADD example_data.json /usr/local/druid/example_data.json

# Setup supervisord
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Clean up
RUN apt-get clean && rm -rf /tmp/* /var/tmp/*

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 3306: MySQL
# - 2181 2888 3888: ZooKeeper
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 3306
EXPOSE 2181 2888 3888

WORKDIR /var/lib/druid
ENTRYPOINT export HOSTIP="$(resolveip -s $HOSTNAME)" && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
