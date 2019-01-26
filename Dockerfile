FROM debian:stretch

# package versions
ARG UNRAR_VERSION="5.6.4"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# install build packages
RUN \
	apt-get update \
	&& apt-get install -y \
		curl \
		g++ \
		make

# fetch source code
RUN \
	set -ex \
	&& curl -o \
	/tmp/unrar.tar.gz -L \
	"http://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" \
	&& mkdir -p \
		/tmp/unran-src \
	&& tar xf \
	/tmp/unrar.tar.gz -C \
	/tmp/unran-src --strip-components=1

# build and archive package
RUN \
	set -ex \
	&& mkdir -p \
		/build \
	&& cd /tmp/unran-src \
	&& make -f makefile \
	&& tar -czvf /build/unrar.tar.gz unrar

# copy files out to /mnt
CMD ["cp", "-avr", "/build", "/mnt/"]
