# autoiso
This is a rudimental unattended installer booting and installing from iso with net
repository as pakage sources.
You should place distro isos into OS-ISO, edit create-host.sh-sample to fit 
upcoming platform needs and run it.
You will find your per host iso image into tgtiso

## Install real software

### deb 
apt-get -y install xorriso genisoimage

### Centos
yum -y install xorriso genisoimage

## Usage

```
su -
cd OS-ISOS/
bash get_centos.sh
bash get_debian.sh
bash get_ubuntu.sh
cd ..

cp create-host.sh-sample create-platformname.sh

#edit create-platformname.sh

bash create-platformname.sh

ls tgtiso
tgtiso/DESC-CentOS-x86_64-testvm01.test.iso
```
