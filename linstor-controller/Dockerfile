FROM ubuntu:bionic as builder

ENV LINSTOR_VERSION 0.7.1
ENV LINSTOR_PACKAGE linstor-server-${LINSTOR_VERSION}

RUN groupadd makepkg \
 && useradd -m -g makepkg makepkg

RUN apt-get update -y \
 && apt-get install -y \
      debhelper \
      default-jdk-headless \
      dh-systemd \
      python-all \
      gradle \
      javahelper

USER makepkg

RUN curl -L https://github.com/LINBIT/linstor-server/archive/v${LINSTOR_VERSION}.tar.gz \
  | tar -xzf - -C /home/makepkg ${LINSTOR_PACKAGE}/debian
RUN curl http://www.linbit.com/downloads/linstor/${LINSTOR_PACKAGE}.tar.gz \
  | tar -xzf - -C /home/makepkg

RUN cd /home/makepkg/${LINSTOR_PACKAGE} \
 && debuild -us -uc -i -b

FROM ubuntu:bionic
COPY --from=builder /home/makepkg/*.deb /tmp/
RUN apt-get update -y \
 && apt-get install -y default-jre-headless \
 && dpkg -i /tmp/linstor-common*.deb \
 && dpkg -i /tmp/linstor-controller*.deb \
 && rm -f /tmp/*.deb \
 && apt-get clean -y \
 && mkdir -p /config /logs \
 && /usr/share/linstor-server/bin/linstor-config create-db-file \
      /data/linstordb > /config/database.cfg

# Install postgresql connector
ENV JDBC_POSTGRESQL_VERSION 42.2.2
ADD https://jdbc.postgresql.org/download/postgresql-${JDBC_POSTGRESQL_VERSION}.jar \
      /usr/share/linstor-server/lib/postgresql-${JDBC_POSTGRESQL_VERSION}.jar

EXPOSE 3376/tcp 3377/tcp
CMD [ "/usr/share/linstor-server/bin/Controller", "--logs=/logs", "--config-directory=/config" ]
