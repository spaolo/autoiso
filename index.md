## Welcome to VMWCDLU aka MVCCDVAS homepage

Need of automating your Linux installation though you yearn out old good days when OS were used to be installed from CDs (or floppies...)?

Now you can have both

This bash script will create an auto-installing bootable iso for your Linux installation without the need of a DHCP or PXE by raping original distro ISOS.


### Try it now

```

gpt-get -y install xorriso genisoimage
#or
yum -y install xorriso genisoimage

git clone https://github.com/spaolo/autoiso

cd OS-ISOS/
bash get_centos.sh
bash get_debian.sh
bash get_ubuntu.sh

cp create-host.sh-sample create-envname.sh
vi create-envname.sh
#edit main parameters and add any host you want to

bash create-envname.sh

ls tgtiso

tgtiso/DESC-CentOS-x86_64-testvm01.test.iso
```
Now transfert your ISO file to your host and take your coffee meanwhile installing

### Success stories

#### Tennessee whiskey man style

We still burn ISOS to CD and insert them in bare metal hardware

#### VMWare rackless style

Transferring ISOS to VMWare datastore by scp it's an undeniable pleasure

#### VMWare Negotiator syle

Ovftool based automation are a not-so-bad process.

### Support or Contact

Support ? Computer says no, you can open a issue but...

