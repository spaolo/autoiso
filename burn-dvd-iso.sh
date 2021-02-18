#!/bin/bash
#{functions
function choose_dfl_kickfile {
	if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then	T_KICKFILE=preseeds/centos-ks.cfg
	elif [ $OS_NAME == 'debian' ]
	then	T_KICKFILE=preseeds/debian-preseed-deb9.cfg
	elif [ $OS_NAME == 'Ubuntu' ]
	then	T_KICKFILE=preseeds/ubuntu-preseed.cfg
	fi 
	echo $T_KICKFILE
}

function choose_tgt_kickfile {
	if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then	T_KICKFILE=$DEST_FS/ks/centos-ks.cfg
	elif [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ]
	then	T_KICKFILE=$TMP_INITRD_DIR/preseed.cfg
	fi 
	echo $T_KICKFILE
}

function choose_src_initrd {
	if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then	T_INITRD=$DEST_FS/isolinux/initrd.img
	elif [ $OS_NAME == 'debian' ]
	then	T_INITRD=$DEST_FS/initrd.gz
	elif  [ $OS_NAME == 'Ubuntu' ]
	then	T_INITRD=$DEST_FS/initrd.gz
	#then	T_INITRD=$DEST_FS/install/netboot/ubuntu-installer/$OS_ARCH/initrd.gz
	fi 
	echo $T_INITRD
}

function choose_tgt_initrd {
	if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then	T_INITRD=$DEST_FS/isolinux/initrd.img
	elif [ $OS_NAME == 'Ubuntu' ] || [ $OS_NAME == 'debian' ]
	then	T_INITRD=$DEST_FS/install/initrd-$HOST_DESC.gz
	#elif [ $OS_NAME == 'debian' ] 
	#then	T_INITRD=$DEST_FS/initrd-$HOST_DESC.gz
	fi 
	echo $T_INITRD
}

function choose_iso_vmlinuz {
	if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ] 
	then	T_VMLIN=vmlinuz
	elif [ $OS_NAME == 'Ubuntu' ]
	#then	T_VMLIN=/install/vmlinuz
	then	T_VMLIN=/linux
	elif [ $OS_NAME == 'debian' ]
	then	T_VMLIN=/linux
	fi 
	echo $T_VMLIN
}

function choose_ksurl {
        if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
        #cdrom:/ks/centos-ks.cfg
        then    T_KSURL=cdrom:/ks/centos-ks.cfg
        elif [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ]
        then    T_KSURL=/preseed.cfg
        fi
        echo $T_KSURL
}

function choose_isolinux_cfg {
        if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
        then    T_ISOLINUX=$DEST_FS/isolinux/isolinux.cfg
        elif [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ]
        then    T_ISOLINUX=$DEST_FS/isolinux.cfg
        fi
        echo $T_ISOLINUX
}
function choose_isolinux_bin {
        if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
        then    T_ISOLINUX=isolinux/isolinux.bin
        elif [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ]
        then    T_ISOLINUX=isolinux.bin #mini iso
        fi
        echo $T_ISOLINUX
}
function choose_isolinux_cat {
        if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ] || [ $OS_NAME == 'Ubuntu' ]
        then    T_ISOLINUX=isolinux/boot.cat
        elif [ $OS_NAME == 'debian' ] 
        then    T_ISOLINUX=boot.cat #mini iso
        fi
        echo $T_ISOLINUX
}

function prep_centos_boot {
	INSERT_BEFORE_LINE=$(\grep -n "^label linux$" $SRC_ISOLINUX|cut -d':' -f1)
	ISOLINUX_LINES=$(grep -c "^" $SRC_ISOLINUX)
	
	let TAIL_LINES=$ISOLINUX_LINES-$INSERT_BEFORE_LINE
	
	let TAIL_LINES++
	let INSERT_BEFORE_LINE--
	
	head -$INSERT_BEFORE_LINE $SRC_ISOLINUX\
		|sed -e "s/^timeout [0-9]\{1,\}/timeout 300/" \
	 	> $TMP_ISOLINUX

#aggiungi il boot con il kickstart
cat >> $TMP_ISOLINUX << EOF
label $HOST_DESC
  menu label ^Install $HOSTNAME
  menu default
  kernel vmlinuz
  append initrd=initrd.img text ip=$IPADDR netmask=$NETMASK gateway=$GATEWAY dns=212.97.32.2 ks=$KSURL
EOF
  #append initrd=initrd.img text ksdevice=ens160 ip=$IPADDR netmask=$NETMASK gateway=$GATEWAY dns=212.97.32.2 ks=$KSURL
	tail -$TAIL_LINES $SRC_ISOLINUX \
		|grep -v "menu default" >> $TMP_ISOLINUX

cp $TMP_ISOLINUX $TGT_ISOLINUX
}

function prep_deb_uefi {
	INSERT_BEFORE_LINE=$(\grep -n "^menuentry 'Install'" $TGT_GRUB|head -1|cut -d':' -f1)
	GRUB_LINES=$(grep -c "^" $TGT_GRUB)
	let TAIL_LINES=$GRUB_LINES-$INSERT_BEFORE_LINE
	let TAIL_LINES++
	let INSERT_BEFORE_LINE--
	head -$INSERT_BEFORE_LINE $TGT_GRUB\
                > $TGT_GRUB.tmp
	echo "set timeout=100" >> $TGT_GRUB.tmp
cat >> $TGT_GRUB.tmp << EOF 
menuentry 'Install $HOSTNAME' {
    set background_color=black
    linux   $ISO_VMLINUZ vga=788 --- file=$KSURL
    initrd  /install/initrd-$HOST_DESC.gz 
}
EOF
	tail -$TAIL_LINES $TGT_GRUB \
		>> $TGT_GRUB.tmp
	mv $TGT_GRUB.tmp $TGT_GRUB
}

function prep_deb_boot {
	#modifica le opzioni di boot per txt.cfg
	INSERT_BEFORE_LINE=$(\grep -n "^default install" $SRC_ISOLINUX_DEB|cut -d':' -f1)
	if [ X$INSERT_BEFORE_LINE == X ]
	then 
		INSERT_BEFORE_LINE=$(\grep -n "^label install" $SRC_ISOLINUX_DEB|cut -d':' -f1)
	fi
	ISOLINUX_LINES=$(grep -c "^" $SRC_ISOLINUX_DEB)
	let TAIL_LINES=$ISOLINUX_LINES-$INSERT_BEFORE_LINE
	
	let TAIL_LINES++
	let INSERT_BEFORE_LINE--

	head -$INSERT_BEFORE_LINE $SRC_ISOLINUX_DEB \
		|sed -e "s/^timeout [0-9]\{1,\}/timeout 100/" \
	 	> $TMP_ISOLINUX_DEB

cat >> $TMP_ISOLINUX_DEB << EOI
default $HOST_DESC
label $HOST_DESC
  menu label ^Install $HOSTNAME
  kernel $ISO_VMLINUZ
  append file=$KSURL vga=normal auto=true initrd=/install/initrd-$HOST_DESC.gz
EOI
	tail -$TAIL_LINES $SRC_ISOLINUX_DEB \
		|egrep -v "default install|menu default" >> $TMP_ISOLINUX_DEB
	cp $TMP_ISOLINUX_DEB $TGT_ISOLINUX_DEB

	#imposta il timeout
	cat $SRC_ISOLINUX \
		|sed -e "s/^timeout [0-9]\{1,\}/timeout 100/" \
		> $TMP_ISOLINUX
}

function prep_centos_initrd {
	mkdir -p $TMP_INITRD_DIR
	cd $TMP_INITRD_DIR
	xzcat  $BASEDIR/$SRC_INITRD \
		|cpio -i -d -m
	#dns ptr override hostname
	echo "$IPADDR    $HOSTNAME" >> etc/hosts
	echo "hosts: files dns" >> etc/nsswitch.conf
	echo $HOSTNAME >> etc/hostname
	if [ $FIRMWARE == yes ]
		then
		echo adding firmware.cpio.gz
		zcat $BASEDIR/OS-ISOS/firmware.cpio.gz  |cpio -id
		fi
        find . 2>/dev/null \
		| cpio -c -o \
		| xz -9 --format=lzma > $BASEDIR/$TMP_INITRD
	cd $BASEDIR/
	cp $TMP_INITRD $TGT_INITRD
}
#}functions

ORIG_IMAGE=${ORIG_IMAGE:-"OS-ISOS/debian-amd64-jessie-mini.iso"}
CUSTOMER=${CUSTOMER:-"SPX"}
IPADDR=${IPADDR:-"192.168.0.100"}
HOSTNAME=${HOSTNAME:-"localhost.localdomain"}
ROOTPASSWORD=${ROOTPASSWORD:-"sttruppamelo" }
NETMASK=${NETMASK:-"255.255.255.0"}
GATEWAY=${GATEWAY:-"192.168.0.1"}
NAMESERVER=${NAMESERVER:-"192.168.0.1"}
BASEUSER=${BASEUSER:-"nagios"}
KSDEVICE=${KSDEVICE:-eth0}

FIRMWARE=${FIRMWARE:-no}
UEFI_ISO=${UEFI_ISO:-yes}
#https://wiki.debian.org/it/DebianInstaller/NetbootFirmware
#wget http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.cpio.gz

for i in "$@"
do
case $i in
    --CUSTOMER=*)
    CUSTOMER="${i#*=}"
    shift
    ;;
    --ORIG_IMAGE=*)
    ORIG_IMAGE="${i#*=}"
    shift
    ;;
    --IPADDR=*)
    IPADDR="${i#*=}"
    shift
    ;;
    --NETMASK=*)
    NETMASK="${i#*=}"
    shift
    ;;
    --HOSTNAME=*)
    HOSTNAME="${i#*=}"
    shift
    ;;
    --ROOTPASSWORD=*)
    ROOTPASSWORD="${i#*=}"
    shift
    ;;
    --GATEWAY=*)
    GATEWAY="${i#*=}"
    shift
    ;;
    --BASEUSER=*)
    BASEUSER="${i#*=}"
    shift
    ;;
    --KICKFILE=*)
    KICKFILE="${i#*=}"
    shift
    ;;
    --KSDEVICE=*)
    KSDEVICE="${i#*=}"
    shift
    ;;
    --FIRMWARE=*)
    FIRMWARE="${i#*=}"
    shift
    ;;
    *)
	echo unknown option $i
            # unknown option
    ;;
esac
done


HOSTNAME=$(echo $HOSTNAME|tr "[:upper:]" "[:lower:]")
HOSTSHORT=$(echo $HOSTNAME|sed -e "s/\..*//")
BASEUSER=$(echo $BASEUSER|tr "[:upper:]" "[:lower:]")
BASEDIR=$(pwd)

ORIG_FS=mnt-src
DEST_FS=dst-src




#preparazione variabili
OS_NAME=CentOS
OS_ARCH=i386
#detect os and arch
if [ $(echo $ORIG_IMAGE |grep -ic "centos") -eq 1 ]
	then OS_NAME=CentOS;
elif [ $(echo $ORIG_IMAGE |grep -ic "rhel") -eq 1 ]
	then OS_NAME=RedHat;
elif [ $(echo $ORIG_IMAGE |grep -ic "debian") -eq 1 ]
	then OS_NAME=debian;
elif [ $(echo $ORIG_IMAGE |grep -ic "ubuntu") -eq 1 ]
	then OS_NAME=Ubuntu;
fi 

if [ $(echo $ORIG_IMAGE |grep -ic "i386") -eq 1 ]
	then OS_ARCH=i386;
elif [ $(echo $ORIG_IMAGE |grep -ic "x86_64") -eq 1 ]
	then OS_ARCH=x86_64;
elif [ $(echo $ORIG_IMAGE |grep -ic "amd64") -eq 1 ]
	then OS_ARCH=amd64;
fi

HOST_DESC=$CUSTOMER-$OS_NAME-$OS_ARCH
VOLD=$HOST_DESC
TGT_ISOFILE=tgtiso/$HOST_DESC-$HOSTNAME
TGT_INIRD=$DEST_FS/isolinux/initrd-$HOST_DESC.gz

#VOLID="$(isoinfo  -i $ORIG_IMAGE -d|grep 'Volume id:'|cut -b 12- )-$CUSTOMER"
#VOLID="$(isoinfo  -i $ORIG_IMAGE -d|grep 'Volume id:'|cut -b 12- )"

SPOOLBASE=spool/$HOST_DESC
echo "clean $SPOOLBASE"
rm -rf $SPOOLBASE
mkdir -p $SPOOLBASE

echo "clean $DEST_FS"
rm -rf $DEST_FS 
mkdir -p $DEST_FS

TMP_ISOLINUX=$SPOOLBASE/isolinux.cfg
TMP_ISOLINUX_DEB=$SPOOLBASE/txt.cfg
TMP_KICKFILE=$SPOOLBASE/$HOST_DESC-ks.cfg
TMP_INITRD_DIR=$SPOOLBASE/initrd
TMP_INITRD=$SPOOLBASE/initrd-$HOST_DESC.gz

TGT_INITRD=$(choose_tgt_initrd)
SRC_INITRD=$(choose_src_initrd)
ISO_VMLINUZ=$(choose_iso_vmlinuz)

#specific os variables
KSURL=$(choose_ksurl)
DFL_KICKFILE=$(choose_dfl_kickfile)
TGT_KICKFILE=$(choose_tgt_kickfile)

KICKFILE=${KICKFILE:-$DFL_KICKFILE}
SRC_KICKFILE=$KICKFILE


SRC_ISOLINUX=$(choose_isolinux_cfg)
TGT_ISOLINUX=$SRC_ISOLINUX
ISOLINUX_BIN=$(choose_isolinux_bin)
ISOLINUX_CAT=$(choose_isolinux_cat)

#uefi
SRC_GRUB=$DEST_FS/boot/grub/grub.cfg
TGT_GRUB=$DEST_FS/boot/grub/grub.cfg

#detect os and arch
if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then
	VOLID=$HOST_DESC

#elif [ $OS_NAME == 'Ubuntu' ]
#	then 
#	SRC_ISOLINUX_DEB=$DEST_FS/isolinux/txt.cfg
#	TGT_ISOLINUX_DEB=$DEST_FS/isolinux/txt.cfg
#	NAMESERVER=$(echo $NAMESERVER|sed -e "s/,/ /")
elif [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ]
	then 
	SRC_ISOLINUX_DEB=$DEST_FS/txt.cfg
	TGT_ISOLINUX_DEB=$DEST_FS/txt.cfg
	NAMESERVER=$(echo $NAMESERVER|sed -e "s/,/ /")
fi 

echo clean iso spool
###################################################
#copy dest filesystem iso {
rm -rf $DEST_FS
echo copy iso content
#preparazione iso
mkdir -p $ORIG_FS
mkdir -p $DEST_FS
if [ $(mount |grep -c $ORIG_FS) -gt 0 ]
	then
	echo $ORIG_FS already mounted
	exit
	fi
mount -o loop,ro $ORIG_IMAGE $ORIG_FS

if [ -d $ORIG_FS/isolinux ]
	then rsync -a $ORIG_FS/isolinux $DEST_FS/
	else mkdir -p $DEST_FS/isolinux/
fi
#if [ $OS_NAME == 'Ubuntu' ] 
#	then rsync -a $ORIG_FS/install $DEST_FS/ ; fi

if [ $OS_NAME == 'debian' ] || [ $OS_NAME == 'Ubuntu' ] #taken from miniiso
	then 
	rsync -a $ORIG_FS/ $DEST_FS/
	mkdir -p $DEST_FS/install
	fi

#}copy dest filesystem iso
###################################################

###################################################
#{preparazione kickstart/preseed

sed -e "\
	s/IPADDRESS/$IPADDR/;
	s/NETMASK/$NETMASK/;
	s/GATEWAY/$GATEWAY/;
	s/NAMESERVER/$NAMESERVER/;
	s/ROOTPASSWORD/$ROOTPASSWORD/;
	s/BASEUSER/$BASEUSER/;
	s/HOSTNAME/$HOSTNAME/
	s/HOSTSHORT/$HOSTSHORT/
	s/CPUARCH/$OS_ARCH/
	s/CUSTOMER/$CUSTOMER/
	" \
	$SRC_KICKFILE \
	> $TMP_KICKFILE


#create target kickfile dir
mkdir $(dirname $TGT_KICKFILE)
cp $TMP_KICKFILE $TGT_KICKFILE

#}preparazione kickstart/preseed
###################################################
#echo unpack installer

echo "prep initrd"
#preparazione initramfs con kickstart
if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
	then
	#prep_centos_initrd
	echo no need to initrd

elif [ $OS_NAME == 'Ubuntu' ] || [ $OS_NAME == 'debian' ]
	then
	mkdir -p $TMP_INITRD_DIR
	cd $TMP_INITRD_DIR
	gunzip -c $BASEDIR/$SRC_INITRD \
		|cpio -i -d
        #find . 2>/dev/null | cpio -c -o | xz -9 --format=lzma > /boot/new.img
	#dns ptr override hostname
	echo "$IPADDR    $HOSTNAME" >> etc/hosts
	echo "hosts: files dns" >> etc/nsswitch.conf
	echo $HOSTNAME >> etc/hostname
	if [ $FIRMWARE == yes ]
		then
		echo adding firmware.cpio.gz
		zcat $BASEDIR/OS-ISOS/firmware.cpio.gz  |cpio -id
		fi
	find . |cpio -H newc -o \
		|gzip -c > $BASEDIR/$TMP_INITRD
	cd $BASEDIR/
	cp $TMP_INITRD $TGT_INITRD
fi


if [ $OS_NAME == 'Ubuntu' ] 
	then
	echo remove unnecessary data
	rm -rf $DEST_FS/install/netboot
	fi

#preparazione isolinux redhat
if [ $OS_NAME == 'CentOS' ] || [ $OS_NAME == 'RedHat' ]
then
	prep_centos_boot
elif [ $OS_NAME == 'Ubuntu' ] || [ $OS_NAME == 'debian' ]
then
	prep_deb_boot
	if [ $UEFI_ISO == yes ]
	then prep_deb_uefi; fi
fi

#umount orig iso
umount $ORIG_FS

#ISOHYBRIDMBR=/usr/lib/ISOLINUX/isohdpfx.bin
ISOHYBRIDMBR=/usr/share/syslinux/isohdpfx.bin
############################################################################
echo "build new isofs"
mkdir -p tgtiso

if [ $UEFI_ISO == yes ]
then
xorriso -as mkisofs -graft-points \
	-b $ISOLINUX_BIN -no-emul-boot -boot-info-table -boot-load-size 4 -c $ISOLINUX_CAT \
	-isohybrid-mbr $ISOHYBRIDMBR \
	-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat \
	-V "$VOLID" -o "$TGT_ISOFILE.iso" -r \
	"$DEST_FS" --sort-weight 0 / --sort-weight 1 /boot 
else
genisoimage -o $TGT_ISOFILE.iso  \
	-b $ISOLINUX_BIN \
	-c $ISOLINUX_CAT \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-l -allow-leading-dots -relaxed-filenames -joliet-long -max-iso9660-filenames \
	-D -R -J -T -V "$VOLID" \
	$DEST_FS/
fi
#isohybrid --uefi  $TGT_ISOFILE.iso

rm -rf $SPOOLBASE
rm -rf $DEST_FS
