ARG ALPINE_VERSION="3.19"
FROM alpine:$ALPINE_VERSION as fetch-stage

# build arguments
ARG RELEASE

############## fetch stage ##############

# install fetch packages
RUN \
	set -ex \
	&& apk add --no-cache \
		bash \
		curl \
		grep

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch source
RUN \
	if [ -z ${RELEASE+x} ]; then \
	RELEASE=$(curl -sX GET https://www.rarlab.com/rar_add.htm | grep -Po '(?<=rar/unrarsrc-).*(?=.tar)'); \
	fi \
	&& mkdir -p \
		/src/unrar \
	&& curl -o \
	/tmp/unrar.tar.gz -L \
	"https://www.rarlab.com/rar/unrarsrc-${RELEASE}.tar.gz" \
	&& tar xf \
	/tmp/unrar.tar.gz -C \
	/src/unrar --strip-components=1


FROM alpine:$ALPINE_VERSION as build-stage

############## build stage ##############

# install build packages
RUN \
	set -ex \
	&& apk add --no-cache \
		g++ \
		make

# copy artifacts from fetch stage
COPY --from=fetch-stage /src/unrar /src/unrar

# set workdir 
WORKDIR /src/unrar

# build package
RUN \
	set -ex \
	&& mkdir -p \
		/build \
	&& make LDFLAGS=-static -f makefile


FROM alpine:$ALPINE_VERSION

############## package stage ##############

# build arguments
ARG RELEASE

# copy fetch and build artifacts
COPY --from=build-stage /src/unrar /src/unrar

# set workdir
WORKDIR /src/unrar

# install packages
RUN \
	set -ex \
	&& apk add --no-cache \
		bash \
		curl \
		grep

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# archive package
# hadolint ignore=SC1091
RUN \
	if [ -z ${RELEASE+x} ]; then \
	RELEASE=$(curl -sX GET https://www.rarlab.com/rar_add.htm | grep -Po '(?<=rar/unrarsrc-).*(?=.tar)'); \
	fi \
	&& set -ex \
	&& mkdir -p \
		/build \
	&& tar -czvf /build/unrar-"${RELEASE}".tar.gz unrar \
	&& chown -R 1000:1000 /build

# copy files out to /mnt
CMD ["cp", "-avr", "/build", "/mnt/"]
