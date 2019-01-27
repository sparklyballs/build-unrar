FROM debian:stretch

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# install build packages
RUN \
	apt-get update \
	&& apt-get install -y \
		curl \
		g++ \
		make

# get package version
RUN \
	UNRAR_RELEASE=`curl -s https://www.rarlab.com/rar_add.htm | grep -Eo 'unrarsrc-.*.tar.gz' | cut -d'-' -f2-  | cut -d'.' -f1,2,3)` \
	&& echo "UNRAR_VERSION=${UNRAR_RELEASE}" > /tmp/version.txt

# fetch source code
RUN \
	set -ex \
	&& . /tmp/version.txt \
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
	&& . /tmp/version.txt \
	&& mkdir -p \
		/build \
	&& cd /tmp/unran-src \
	&& make -f makefile \
	&& tar -czvf /build/unrar-${UNRAR_VERSION}.tar.gz unrar

# copy files out to /mnt
CMD ["cp", "-avr", "/build", "/mnt/"]
