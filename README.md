# docker-cirros-builder

docker-cirros-builder is a docker container that ships everything needed to build
(and customize) x86-64-cirros images.

You can find the home of cirros [here](https://launchpad.net/cirros).

The current container uses

* cirros 0.3.3
* buildroot 2015.2
* uClib 0.33.2
* busybox 1.23.1
* gcc 4.8.4

and offers some convenience scripts:

* cirros-build                - build cirros firmware
* cirros-build-image          - build cirros images
* cirros-config-image         - config buildroot environment
* cirros-config-image-busybox - configure busybox used within cirros

__NOTE:__ The first run of 'cirros-build-image' triggers the download of a grub package.

To make the generated images easily available on the host machine you may
start the instance with a shared directory attached (see example below).

__NOTE:__ This container must be run in privileged mode since it uses loop-mounts.

## example

### setup

Create the container on your own:
```
host> docker build -t cirros_x86_64_builder .
...
< this will take some time (for me ... ~15 min) >
...
```

Or just take the published one from docker hub:
```
host> docker pull hecke/cirros_x86_64_builder 
```

Start the instance:
```
host> docker run --privileged -i -v /tmp/cirros_img/:/root/build/cirros-0.3.3/output/x86_64/images/ -t hecke/cirros_x86_64_builder
```

Inside the container:
```
root@667d9cbe3a20:~/build/cirros-0.3.3# cirros-build-image
...
wrote /root/build/cirros-0.3.3/output/x86_64/images/part.img
wrote /root/build/cirros-0.3.3/output/x86_64/images/disk.img
wrote /root/build/cirros-0.3.3/output/x86_64/images/kernel
wrote /root/build/cirros-0.3.3/output/x86_64/images/initramfs
wrote /root/build/cirros-0.3.3/output/x86_64/images/blank.img
wrote /root/build/cirros-0.3.3/output/x86_64/images/filesys.tar.gz
...
```

__NOTE:__ The format of 'disk.img' is qcow2.

### naked qemu

Just start the instance:
```
host> sudo qemu-system-x86_64 -curses /tmp/cirros_img/disk.img
```

### libvirt

Create a VM using the cirros image:
```
host> virt-install \
          --connect qemu:///system \
          --virt-type qemu \
          --arch x86_64 \
          --name cirros \
          --ram 64 \
          --disk path=/tmp/cirros_img/disk.img,format=qcow2 \
          --boot hd \
          --vnc \
          --network network=default,mac=52:54:00:9c:42:23 \
          --os-type linux
```