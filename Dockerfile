ARG ALPINE_VERSION="3.9"
FROM alpine:$ALPINE_VERSION as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	set -ex \
	&& apk add --no-cache \
		bash \
		curl

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch source code
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/tmp/unrar-src \
	&& curl -o \
	/tmp/unrar.tar.gz -L \
	"https://www.rarlab.com/rar/unrarsrc-${UNRAR_RELEASE}.tar.gz" \
	&& tar xf \
	/tmp/unrar.tar.gz -C \
	/tmp/unrar-src --strip-components=1

FROM alpine:$ALPINE_VERSION as build-stage

############## build stage ##############

# install build packages
RUN \
	set -ex \
	&& apk add --no-cache \
		g++ \
		make

# copy artifacts from fetch stage
COPY --from=fetch-stage /tmp/unrar-src /tmp/unrar-src

# set workdir 
WORKDIR /tmp/unrar-src

# build package
RUN \
	set -ex \
	&& mkdir -p \
		/build \
	&& make LDFLAGS=-static -f makefile


FROM alpine:$ALPINE_VERSION

############## package stage ##############

# copy fetch and build artifacts
COPY --from=build-stage /tmp/unrar-src /tmp/unrar-src
COPY --from=fetch-stage /tmp/version.txt /tmp/version.txt

# set workdir
WORKDIR /tmp/unrar-src

# archive package
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/build \
	&& tar -czvf /build/unrar-"${UNRAR_RELEASE}".tar.gz unrar \
	&& chown 1000:1000 /build/unrar-"${UNRAR_RELEASE}".tar.gz

# copy files out to /mnt
CMD ["cp", "-avr", "/build", "/mnt/"]
