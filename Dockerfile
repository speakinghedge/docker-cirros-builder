FROM debian:7.8

MAINTAINER hecke <hecke@naberius.de>

RUN apt-get update && apt-get install -y \
	bc \
	cpio \
	gcc-multilib \
	g++ \
	kmod \
	libncurses5 \
	libncurses5-dev \
	make \
	python \
	qemu-utils \
	quilt \
	unzip \
	wget

RUN mkdir /root/source && mkdir /root/build 

RUN wget http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-source.tar.gz -O /root/source/cirros-0.3.3-source.tar.gz && tar -xf /root/source/cirros-0.3.3-source.tar.gz -C /root/build

RUN wget http://buildroot.uclibc.org/downloads/buildroot-2015.02.tar.gz -O /root/source/buildroot-2015.02.tar.gz && tar -xf /root/source/buildroot-2015.02.tar.gz -C /root/build

# link buildroot into cirros build env
RUN ln -snf /root/build/buildroot-2015.02 /root/build/cirros-0.3.3/buildroot

# get recent linux kernel (used by bundle script to generate images)
RUN wget http://de.archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-image-3.19.0-12-generic_3.19.0-12.12_amd64.deb -O /root/source/linux-image-3.19.0-12-generic_3.19.0-12.12_amd64.deb

# disable sudoers patch (for now), apply remaining patches
RUN sed -i '/sudo-install-sudoers-so.patch/d' /root/build/cirros-0.3.3/patches-buildroot/series 
RUN ( cd /root/build/cirros-0.3.3/buildroot &&  QUILT_PATCHES=/root/build/cirros-0.3.3/patches-buildroot quilt push -a )

# copy adapted .config file
# build target: x86_64, all legacy entries disabled
ADD cirros_0.3.3/buildroot_2015.02/x86_64/buildroot-x86_64.config /root/build/cirros-0.3.3/conf/buildroot-x86_64.config

# get buildroot sources
RUN (cd /root/build/cirros-0.3.3 && make ARCH=x86_64 br-source)

# fix missing buildroot/fs/skeleton (avoid rsync error)
RUN mkdir -p /root/build/cirros-0.3.3/buildroot/fs/skeleton

# initial build 
RUN (cd /root/build/cirros-0.3.3 && make ARCH=x86_64 OUT_D=/root/build/cirros-0.3.3/output/x86_64)

# since bundle uses loop-mounts and build does not offer any way to run in privileged mode this must be done
# in a running container
#RUNP (cd /root/build/cirros-0.3.3 && ./bin/bundle -v output/x86_64/rootfs.tar /root/source/linux-image-3.19.0-12-generic_3.19.0-12.12_amd64.deb output/x86_64/images)

# add some convenience scripts & motd info
COPY cirros_0.3.3/buildroot_2015.02/x86_64/cirros-* /usr/bin/
COPY cirros_0.3.3/buildroot_2015.02/motd /etc/motd
RUN chmod +x /usr/bin/cirros-*

CMD (cd /root/build/cirros-0.3.3 && cat /etc/motd && /bin/bash)