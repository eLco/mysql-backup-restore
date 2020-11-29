FROM debian:buster-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    openssl \
    perl \
    gnupg \
    dirmngr \
    wget \
    curl \
    unzip \
    mydumper \
    percona-toolkit \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

RUN set -ex; \
    # gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
    key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"; \
    apt-key list > /dev/null

ENV MYSQL_MAJOR 5.7
ENV MYSQL_VERSION 5.7.32-1debian10

RUN echo 'deb http://repo.mysql.com/apt/debian/ buster mysql-5.7' > /etc/apt/sources.list.d/mysql.list

RUN apt-get update \
    && apt-get install -y \
    mysql-client="${MYSQL_VERSION}" 

CMD ["bash"]