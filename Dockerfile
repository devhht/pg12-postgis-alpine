FROM postgres:12-alpine
MAINTAINER <devhht@icloud.com>
LABEL description="PG12ALPINE+POSTGIS"

#---------------------------------------------------------------------------------------
#FOR China
#ENV ALPINE_MIRROR_BASE https://mirror.tuna.tsinghua.edu.cn
ENV ALPINE_MIRROR_BASE http://dl-cdn.alpinelinux.org
ENV ALPINE_MIRROR_VERSION v3.10

RUN echo "$ALPINE_MIRROR_BASE/alpine/$ALPINE_MIRROR_VERSION/main" > /etc/apk/repositories
RUN echo "$ALPINE_MIRROR_BASE/alpine/$ALPINE_MIRROR_VERSION/community" >> /etc/apk/repositories

#---------------------------------------------------------------------------------------
ENV POSTGIS_VERSION 3.0.0
ENV POSTGIS_SHA256 1c83fb2fc8870d36ed49859c49a12c8c4c8ae8c5c3f912a21a951c5bcc249123


RUN wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz"


RUN set -ex \
    && apk update \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
&& apk add --no-cache --virtual .build-deps-llvm \
        llvm-dev clang clang-dev \
&& apk add --no-cache --virtual .build-deps \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/main" \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/testing" \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        linux-headers \
        sqlite-dev \
        protobuf-c-dev \
        \
&& apk add --no-cache \
        sqlite \
        protobuf-c


RUN echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file /postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm /postgis.tar.gz \

&& apk add --no-cache --virtual .build-deps-edge \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/main" \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/testing" \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/community" \
        gdal-dev \
        geos-dev \
        proj-dev \
        protobuf-c-dev

RUN cd /usr/src/postgis \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/main" \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/testing" \
        --repository "$ALPINE_MIRROR_BASE/alpine/edge/community" \
        geos \
        gdal \
        proj \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-edge .build-deps-llvm

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/



