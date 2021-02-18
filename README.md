# Install
This is a rudimental unattended installer booting from iso and installing from net
you should place distro isos into OS-ISO, model create-host.sh-sample as preferred
and then run it, you will find your per host iso image into tgtiso

## deb 
apt-get -y install xorriso genisoimage

## Centos
yum -y install xorriso genisoimage

# Usage

```
cd OS-ISOS/
bash get_centos.sh
bash get_debian.sh
bash get_ubuntu.sh
```
