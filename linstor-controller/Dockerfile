FROM debian:stretch
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && wget -O- https://packages.linbit.com/package-signing-pubkey.asc \
      | apt-key add - \
 && echo "deb http://packages.linbit.com/proxmox/ proxmox-5 drbd-9.0" \
      > /etc/apt/sources.list.d/linbit.list \
 && wget http://download.proxmox.com/debian/proxmox-ve-release-5.x.gpg \
      -O /etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg \
 && echo "deb http://download.proxmox.com/debian/pve stretch pve-no-subscription" \
      > /etc/apt/sources.list.d/pve-install-repo.list \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get clean

# Install tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Install linstor-server
RUN apt-get update \
 && apt-get install -y linstor-server \
 && apt-get clean \
 && mkdir -p /config \
 && ln -sf /config/database.cfg /opt/linstor-server/database.cfg \
 && /opt/linstor-server/bin/linstor-config create-db-file \
      /data/linstordb > /config/database.cfg

# Install postgresql connector
ENV JDBC_POSTGRESQL_VERSION 42.2.2
RUN wget -O /opt/linstor-server/lib/postgresql-${JDBC_POSTGRESQL_VERSION}.jar \
      https://jdbc.postgresql.org/download/postgresql-${JDBC_POSTGRESQL_VERSION}.jar \
&& sed -i /opt/linstor-server/bin/* \
     -e "/^CLASSPATH=\$CLASSPATH/d" \
     -e "/^CLASSPATH=/aCLASSPATH=\$CLASSPATH:\$APP_HOME/lib/postgresql-${JDBC_POSTGRESQL_VERSION}.jar"

WORKDIR "/opt/linstor-server"
CMD [ "/opt/linstor-server/bin/Controller" ]
