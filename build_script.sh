#!/bin/bash

prepare() {
	#Get the OpenWrt Core Source for Firmware
	svn checkout -r 33502 svn://svn.openwrt.org/openwrt/trunk/ ./build_dir
	#apply own feeds.conf
	cp ./build_patches/feeds.conf ./build_dir/feeds.conf

	test -d ./build_dir/feeds && /bin/rm -rf ./build_dir/feeds

	./build_dir/scripts/feeds update
	
	./build_dir/scripts/feeds install -a

	#Upgrade batman advanced to version 2012.2.0
	# not needed atm, because in recent openwrt it's uptodate
	#svn update --revision=32789 ./build_dir/feeds/packages/net/batman-adv/

	#fix mktools build error on arch linux
	# hope it's fixed upstream
	#cp ./build_patches/011-missing_unistd.patch ./build_dir/tools/mklibs/patches/

	# fix some tinc mem leaks
	# this patch was a backport and isn't needed anymore
	#mkdir ./build_dir/feeds/packages/net/tinc/patches
	#cp ./build_patches/tinc/001_fix_a_few_small_memory_leaks.patch ./build_dir/feeds/packages/net/tinc/patches/001_fix_a_few_small_memory_leaks.patch


	# don't know what's the state of this. we have to take a look again later...
	case "$1" in
		"dir300")
			#svn export ./build_patches/ar231x/260_fixdmaoffset.patch ./build_dir/target/linux/atheros/patches-2.6.30/260_fixdmaoffset.patch
			#svn export ./build_patches/dir300/990_fix_wifi_led.patch ./build_dir/package/mac80211/patches/990_fix_wifi_led.patch
			;;
		"fonera")
			#svn export ./build_patches/ar231x/260_fixdmaoffset.patch ./build_dir/target/linux/atheros/patches-2.6.30/260_fixdmaoffset.patch
			;;
	esac

	#fix bad switch behaveior:
	# also .. later ..
	#/bin/rm ./build_dir/target/linux/atheros/base-files/etc/uci-defaults/network

	#Apply https://dev.openwrt.org/changeset/32128/branches/backfire
#	/bin/rm ./build_dir/tools/mklibs/patches/001-missing_stdio.patch
#	wget -O ./build_dir/tools/mklibs/patches/001-missing_includes.patch https://dev.openwrt.org/export/32128/branches/backfire/tools/mklibs/patches/001-missing_includes.patch

	# also .. later ..
	#mkdir ./build_dir/tools/m4/patches
	#wget -O ./build_dir/tools/m4/patches/100-fix-gets-removal.patch https://dev.openwrt.org/export/32648/trunk/tools/m4/patches/100-fix-gets-removal.patch

	# also .. later ..
	#mkdir ./build_dir/tools/bison/patches
	#wget -O ./build_dir/tools/bison/patches/100-fix-gets-removal.patch https://dev.openwrt.org/export/32649/trunk/tools/bison/patches/100-fix-gets-removal.patch
}

configure_build() {
	#create filesdir for our config
	test -d ./build_dir/files || mkdir ./build_dir/files

	cp -r ./root_file_system/default/* ./build_dir/files/
	case "$1" in
		"dir300")
			cp ./build_configuration/Atheros_AR231x_AR5312/.config ./build_dir/.config
			cp build_configuration/Atheros_AR231x_AR5312/kernel_config-3.3 build_dir/target/linux/atheros/config-3.3
			cp -r ./root_file_system/dir300/* ./build_dir/files/
			;;
		"fonera")
			cp ./build_configuration/Atheros_AR231x_AR5312/.config ./build_dir/.config
			cp -r ./root_file_system/fonera/* ./build_dir/files/
			;;
		"wrt54g_ap")
			cp ./build_configuration/Broadcom_BCM947xx_953xx_ap/.config ./build_dir/.config
			cp -r ./root_file_system/wrt54g_ap/* ./build_dir/files/
			;;
		"wrt54g_adhoc")
			cp ./build_configuration/Broadcom_BCM947xx_953xx_adhoc/.config ./build_dir/.config
			cp -r ./root_file_system/wrt54g_adhoc/* ./build_dir/files/
			;;
		"dir300b_ap")
			cp ./build_configuration/ramips_rt3050/.config ./build_dir/.config
			cp -r ./root_file_system/dir300b_ap/* ./build_dir/files/
			;;
		"dir300b_adhoc")
			cp ./build_configuration/ramips_rt3050/.config ./build_dir/.config
			cp -r ./root_file_system/dir300b_adhoc/* ./build_dir/files/
			;;
		"wr1043nd")
			cp ./build_configuration/Atheros_AR71xx_AR7240_AR913x/.config_wr1043nd ./build_dir/.config
			cp -r ./root_file_system/wr1043nd/* ./build_dir/files/
			;;
		"wr741nd")
			cp ./build_configuration/Atheros_AR71xx_AR7240_AR913x/.config_wr741nd ./build_dir/.config
			cp -r ./root_file_system/wr741nd/* ./build_dir/files/
			;;
		"wr841nd")
			echo "Nothing implemented for wr841nd";
			;;
		*)
			echo "ERROR";
			;;
	esac

	#insert actual firware version informations into release file
	echo "FIRMWARE_VERSION=\"trunk\"" > ./build_dir/files/etc/firmware_release
	echo "RELEASE_DATE=\"\"" >> ./build_dir/files/etc/firmware_release
	echo "FIRMWARE_REVISION=\"build date: "`date`"\"" >> ./build_dir/files/etc/firmware_release
	echo "OPENWRT_CORE_REVISION=\""`svn info ./build_dir |grep Revision: |cut -c11-`"\"" >> ./build_dir/files/etc/firmware_release
	echo "OPENWRT_FEEDS_PACKAGES_REVISION=\""`svn info ./build_dir/feeds/packages |grep Revision: |cut -c11-`"\"" >> ./build_dir/files/etc/firmware_release
}

build() {
	cd ./build_dir
	case "$2" in
		"debug")
			make V=99
			;;
		"fast")
			ionice -c 2 -- nice -n 1 -- make -j12
			;;
		*)
			ionice -c 3 -- nice -n 10 -- make -j8
			;;
	esac
	# actually this does northing!
	# rm -rf ./build_dir/files/
	cd ../

	if [ ! -d bin ]; then
		mkdir bin
	fi
	
	case "$1" in
		"dir300")
			cp ./build_dir/bin/atheros/openwrt-atheros-root.squashfs ./bin/openwrt-$1-root.squashfs
			cp ./build_dir/bin/atheros/openwrt-atheros-vmlinux.lzma ./bin/openwrt-$1-vmlinux.lzma
			cp ./build_dir/bin/atheros/openwrt-atheros-combined.squashfs.img ./bin/openwrt-$1-combined.squashfs.img
			;;
		"fonera")
			cp ./build_dir/bin/atheros/openwrt-atheros-root.squashfs ./bin/openwrt-$1-root.squashfs
			cp ./build_dir/bin/atheros/openwrt-atheros-vmlinux.lzma ./bin/openwrt-$1-vmlinux.lzma
			cp ./build_dir/bin/atheros/openwrt-atheros-combined.squashfs.img ./bin/openwrt-$1-combined.squashfs.img
			;;
		"dir300b_adhoc" | "dir300b_ap")
			
			#build webflash image
			rm -rf ./bin/openwrt-dir300b1-squashfs-webflash.bin
			./flash_tools/dir300b-flash/v2image -v \
				-i ./build_dir/bin/ramips/openwrt-ramips-rt305x-dir-300-b1-squashfs-sysupgrade.bin \
				-o bin/openwrt-dir300b1-squashfs-webflash.bin \
				-d /dev/mtdblock/2 -s wrgn23_dlwbr_dir300b
			;;
		"wr1043nd")
			cp ./build_dir/bin/ar71xx/openwrt-ar71xx-tl-wr1043nd-v1-squashfs-factory.bin ./bin/
			cp ./build_dir/bin/ar71xx/openwrt-ar71xx-tl-wr1043nd-v1-squashfs-sysupgrade.bin ./bin/
			;;
		"wr741nd")
			cp ./build_dir/bin/ar71xx/openwrt-ar71xx-tl-wr741nd-v1-squashfs-factory.bin ./bin/
			cp ./build_dir/bin/ar71xx/openwrt-ar71xx-tl-wr741nd-v1-squashfs-sysupgrade.bin ./bin/
			;;
		"wrt54g_ap" | "wrt54g_adhoc")
			cp ./build_dir/bin/brcm47xx/openwrt-wrt54g-squashfs.bin ./bin/
			;;
		*)
			echo "Nothing implemented here yet -> missing knowledge!!"
			;;
	esac
}

flash() {
	#Get flash tools
	# i thought they are already there..
	#svn export http://svn.freifunk-ol.de/firmware/Trunk/flash_tools

	if [ ! "`whoami`" = "root" ]
	then
		echo "You need to be root to flash!"
		exit 1
	fi

	echo "Do not plugin your router now, you will be asked to do this later!"
	echo "Stopping Network manager and starting normal network and tftp server..."
	if [ -f /etc/rc.d/networkmanager ];then
		/etc/rc.d/networkmanager stop
		/etc/rc.d/tftpd start
	elif [ -f /etc/init.d/networkmanager ];then
		/etc/init.d/networkmanager stop
		/etc/init.d/tftpd start
	elif [ -f /usr/sbin/invoke-rc.d ];then
		invoke-rc.d tftpd-hpa start || invoke-rc.d tftpd-hpa start || invoke-rc.d tftpd-hpa start || echo "FAILED TO START TFTD"
		invoke-rc.d network-manager stop
	fi

	ifconfig $2 up

	echo "Clearing Firewall!"
	iptables -F
	iptables -P INPUT ACCEPT
	iptables -P OUTPUT ACCEPT

	echo "Flashing now! Please plugin your router into the powerline now"
	case "$1" in
		"dir300")
			if [ -f /usr/sbin/dir300-flash ]; then
				/usr/sbin/dir300-flash $2 ./bin/openwrt-$1-vmlinux.lzma ./bin/openwrt-$1-root.squashfs
			else
				./flash_tools/dir300-flash/dir300-flash.sh $2 ./bin/openwrt-$1-vmlinux.lzma ./bin/openwrt-$1-root.squashfs
			fi
			;;
		"fonera")
			echo "In some cases you have to set a symlink to libpcap to make flashing work (Tim told me that it is evil if I do that for you):"
			echo "ln -s /usr/lib/libpcap.so.1.1.1 /usr/lib/libpcap.so.0.8"

			cd ./flash_tools/fonera-flash/
			./build_libpcap.sh
			cd ../../

			LD_LIBRARY_PATH=`pwd`flash_tools/fonera-flash/libpcap-0.8.1/
			export LD_LIBRARY_PATH

			arch=`uname -m`
			./flash_tools/fonera-flash/ap51-flash-$arch $2 ./bin/openwrt-$1-root.squashfs ./bin/openwrt-$1-vmlinux.lzma freifunc
			;;
		"dir300b_adhoc" | "dir300b_ap")
			echo "* Press RESET on your router and power it on."
			echo "* Now connect it to your Computer using the WAN interface"
			echo "* Configure your Computer to use 192.168.0.2 as IP-Adress"
			echo "* Go to http://192.168.0.1 and flash your router."
			echo "* Happy Freifunk'ing! :-)"
			;;
		*)
			echo "Nothing implemented here yet"
			;;
	esac

	echo "Starting Networkmanager again"
	sleep 5;
	if [ -f /etc/rc.d/networkmanager ];then
		/etc/rc.d/networkmanager start
	elif [ -f /etc/init.d/networkmanager ];then
		/etc/init.d/networkmanager start
	elif [ -f /usr/sbin/invoke-rc.d ];then
		invoke-rc.d tftpd-hpa stop
		invoke-rc.d network-manager start
	fi
}

clean() {
	/bin/rm -rf flash_tools build_dir bin
}

routers() {
	echo "router-types: "
	echo "	dir300"
	echo "	dir300b_adhoc"
	echo "	dir300b_ap"
	echo "	fonera"
	echo "	wrt54g_ap"
	echo "	wrt54g_adhoc"
	echo "	wr741nd"
	echo "	wr1043nd"
}

case "$1" in
	"prepare")
		if [ "$2" = "help" ] || [ "$2" = "" ]; then
			echo "This option fetches the sources for the images and configurates the build so that it can be compiled"
			echo "Usage: $0 $1 router-type"
			routers
		else
			prepare "$2"
			configure_build "$2"
		fi
		;;
	"build")
		if [ "$2" = "help" ] || [ "$2" = "" ]; then
			echo "This option compiles the firmware"
			echo "Normaly the build uses lower IO and System priorities, "
			echo "you can append \"fast\" option, to use normal user priorities"
			echo "Usage: $0 $1 router-type [fast|debug]"
			routers
			echo "Parallel build may fail with revisions before 24969 see https://dev.openwrt.org/ticket/8596"
		else
			build "$2" "$3"
		fi
		;;
	"download")
		if [ "$2" = "help" ] || [ "$2" = "" ]; then
			echo "This option downloads the ready configured images from an external location if needet."
			echo "Usage: $0 $1 http://downloadfolder router-type"
			echo "Common downloadfolder for firmware version 0.3 is http://dev.freifunk-ol.de/firmware/0.3/"
			routers
		else
			mkdir ./bin
			cd ./bin
			wget "$2/$3/openwrt-$3-root.squashfs"
			wget "$2/$3/openwrt-$3-vmlinux.lzma"
			cd ..
		fi
		;;
	"flash")
		if [ "$2" = "help" ] || [ "$2" = "" ]; then
			echo "This option flashes the router."
			echo "$0 $1 router-type net-dev"
			routers
			echo "net-dev:"
			echo "	ethX"
		else
			flash "$2" "$3" "$4"
		fi
		;;
	"clean")
		if [ "$2" = "help" ] || [ "$2" = "" ]; then
			echo "This option cleans all build files."
			echo "$0 $1 all"
		else
			clean
		fi
		;;
	*)
		echo "This is the Build Environment Script of the Freifunk Community Oldenburg."
		echo "Usage: $0 command"
		echo "command:"
		echo "	prepare"
		echo "	build"
		echo "	flash"
		echo "	download"
		echo ""
		echo "If you need help to one of these options just type $0 command help"
	;;
esac
