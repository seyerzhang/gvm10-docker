FROM ubuntu:18.04
 
COPY conf/openvassd.conf /usr/local/etc/openvas/openvassd.conf
COPY script/entrypoint.sh /entrypoint.sh

ENV DEBIAN_FRONTEND=noninteractive \
    GSE_PASSWORD=admin \
    HOSTNAME=gs \
    SRC_DIR=gse-git \
    SRC_PATH=/root/${SRC_DIR} \
    PGUSERNAME=root


RUN apt-get update ;\
    apt-get install apt-utils software-properties-common --no-install-recommends -yq ;\
    apt-get clean ;\
    apt-get update ;\
    apt-get install alien \
        cmake \
        pkg-config \
        libglib2.0-dev \
        libgpgme11-dev \
        uuid-dev \
        libssh-gcrypt-dev \
        libhiredis-dev \
        gcc \
        libgnutls28-dev \
        libpcap-dev \
        libgpgme-dev \
        bison \
        libksba-dev \
        libsnmp-dev \
        libgcrypt20-dev \
        redis-server \
        libsqlite3-dev \
        libical-dev \
        gnutls-bin \
        doxygen \
        nmap \
        libmicrohttpd-dev \
        libxml2-dev \
        apt-transport-https \
        sqlfairy \
        xmltoman \
        xsltproc \
        gcc-mingw-w64 \
        perl-base \
        heimdal-dev \
        libpopt-dev \
        graphviz \
        nodejs \
        rpm \
        nsis \
        wget \
        sshpass \
        socat \
        snmp \
        git \
        libldap2-dev \
        libfreeradius-dev \
        sudo \
        curl \
        python-polib \
        rsync \
        -yq 

RUN curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - ;\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list ;\
    apt-get update ;\
    apt-get install yarn -yq;\
    rm -rf /var/lib/apt/lists/*

RUN mkdir ${SRC_PATH} -p ;\
    cd ${SRC_PATH} ;\
    wget -O gvm-libs-10.0.0.tar.gz https://github.com/greenbone/gvm-libs/archive/v10.0.0.tar.gz ;\
    wget -O openvas-scanner-6.0.0.tar.gz https://github.com/greenbone/openvas-scanner/archive/v6.0.0.tar.gz;\
    wget -O gvmd-8.0.0.tar.gz https://github.com/greenbone/gvmd/archive/v8.0.0.tar.gz ;\
    wget -O gsa-8.0.0.tar.gz https://github.com/greenbone/gsa/archive/v8.0.0.tar.gz ;\
    wget -O openvas-smb-1.0.5.tar.gz https://github.com/greenbone/openvas-smb/archive/v1.0.5.tar.gz ;\
    wget -O ospd-1.3.2.tar.gz https://github.com/greenbone/ospd/archive/v1.3.2.tar.gz

RUN cd ${SRC_PATH} ;\
    find . -name \*.gz -exec tar zxvfp {} \;


RUN  cd ${SRC_PATH}/gvm-libs-10.0.0 ;\
    mkdir build ;\
    cd build ;\
    cmake .. ;\
    make ;\
    make doc-full ;\
    make install ;\
    cd ${SRC_PATH}

RUN  cd ${SRC_PATH}/openvas-smb-1.0.5 ;\
    mkdir build ;\
    cd build/ ;\
    cmake .. ;\
    make ;\
    make install ;\
    cd ${SRC_PATH}

RUN  cd ${SRC_PATH}/openvas-scanner-6.0.0 ;\
    mkdir build ;\
    cd build/ ;\
    cmake .. ;\
    make ;\
    make doc-full ;\
    make install ;\
    cd ${SRC_PATH}

COPY conf/redis.config /etc/redis/redis.conf

RUN service redis-server restart

RUN greenbone-nvt-sync 

RUN cd ${SRC_PATH}/gvmd-8.0.0 ;\
    mkdir build ;\
    cd build/ ;\
    cmake .. ;\
    make ;\
    make doc-full ;\
    make install ;\
    cd ${SRC_PATH}

RUN ldconfig

RUN cd ${SRC_PATH}/gsa-8.0.0 ;\
    sed -i 's/#ifdef GIT_REV_AVAILABLE/#ifdef GIT_REVISION/g' ${SRC_PATH}/gsa-8.0.0/gsad/src/gsad.c ;\
    mkdir build ;\
    cd build/ ;\
    cmake .. ;\
    make ;\
    make doc-full ;\
    make install ;\
    cd ${SRC_PATH}

 # fix certs
RUN gvm-manage-certs -a

# create admin user
RUN gvmd --create-user=admin --password=admin

RUN greenbone-certdata-sync ;\
    greenbone-scapdata-sync

ENV BUILD=""

CMD /entrypoint.sh
EXPOSE 80 443 9390