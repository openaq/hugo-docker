ARG HUGO_VERSION=0.108.0

ARG HUGO_BUILD_TAGS=extended

ARG GO_VERSION=1.19

FROM golang:${GO_VERSION}-buster AS build

ARG HUGO_VERSION
ARG HUGO_BUILD_TAGS

ARG CGO=1
ENV CGO_ENABLED=${CGO}
ENV GOOS=linux
ENV GO111MODULE=on

WORKDIR /go/src/github.com/gohugoio/hugo

# gcc/g++ are required to build SASS libraries for extended version
RUN apt-get install \
      gcc \
      g++ \
      git

# clone source from Git repo:
RUN git clone \
      --branch "v${HUGO_VERSION}" \
      --single-branch \
      --depth 1 \
      https://github.com/gohugoio/hugo.git ./

# https://github.com/gohugoio/hugo/commit/241481931f5f5f2803cd4be519936b26d8648dfd
RUN go build -v -ldflags "-X github.com/gohugoio/hugo/common/hugo.vendorInfo=docker" -tags "$HUGO_BUILD_TAGS" && \
    mv ./hugo /go/bin/hugo

FROM debian:buster

ARG HUGO_VERSION

# https://github.com/sass/dart-sass-embedded/releases
ARG DART_SASS_VERSION=1.56.1

LABEL version="${HUGO_VERSION}"
LABEL repository="https://github.com/openaq/hugo-docker"
LABEL homepage="https://openaq.org/"


COPY --from=build /go/bin/hugo /usr/bin/hugo

RUN   apt-get update && \ 
      apt-get install -y \
      wget \
      tzdata \
      git \
      nodejs \
      npm \
      golang && \
    npm install --global --production \
      yarn \
      postcss \
      postcss-cli \
      autoprefixer \
      @babel/core \
      @babel/cli && \
    npm cache clean --force && \
    wget -O sass-embedded.tar.gz https://github.com/sass/dart-sass-embedded/releases/download/${DART_SASS_VERSION}/sass_embedded-${DART_SASS_VERSION}-linux-x64.tar.gz && \
    tar xf sass-embedded.tar.gz && \
    mv ./sass_embedded/dart-sass-embedded /usr/bin/ && \
    chmod 755 /usr/bin/dart-sass-embedded && \
    rm -rf sass-embedded.tar.gz sass_embedded 

VOLUME /src
WORKDIR /src

EXPOSE 1313

ENTRYPOINT ["hugo"]