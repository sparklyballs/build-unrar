ARG DEBIAN_VERSION="stretch"
FROM debian:$DEBIAN_VERSION as fetch-stage

############## fetch stage ##############

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# install fetch packages
RUN \
	apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		ca-certificates \
		curl \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch source code
RUN \
	set -ex \
	&& mkdir -p \
		/tmp/unrar-src \
	&& UNRAR_VERSION=$(curl -s https://www.rarlab.com/rar_add.htm | \
		grep -Eo 'unrarsrc-.*.tar.gz' | \
		cut -d'-' -f2-  | \
		cut -d'.' -f1,2,3) \
	&& curl -o \
	/tmp/unrar.tar.gz -L \
	"https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" \
	&& tar xf \
	/tmp/unrar.tar.gz -C \
	/tmp/unrar-src --strip-components=1 \
	&& echo "UNRAR_VERSION=${UNRAR_VERSION}" > /tmp/version.txt

FROM debian:$DEBIAN_VERSION as build-stage

############## build stage ##############

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# install build packages
RUN \
	set -ex \
	&& apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		g++ \
		make \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# copy artifacts from fetch stage
COPY --from=fetch-stage /tmp/unrar-src /tmp/unrar-src

# set workdir 
WORKDIR /tmp/unrar-src

# build package
RUN \
	set -ex \
	&& mkdir -p \
		/build \
	&& make -f makefile


FROM debian:$DEBIAN_VERSION

############## package stage ##############

# copy fetch and build artifacts
COPY --from=build-stage /tmp/unrar-src /tmp/unrar-src
COPY --from=fetch-stage /tmp/version.txt /tmp/version.txt

# set workdir
WORKDIR /tmp/unrar-src

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# archive package
RUN \
	source /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/build \
	&& tar -czvf /build/unrar-"${UNRAR_VERSION}".tar.gz unrar

# copy files out to /mnt
CMD ["cp", "-avr", "/build", "/mnt/"]
# hadolint ignore=SC1091
