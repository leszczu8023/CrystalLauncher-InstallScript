#!/bin/bash

INSTALL_DIR=~/.crystalLauncher

JRE_I586='http://mirr2.crystal-launcher.pl/jre/jre-8u181-linux-i586.tar.gz'
JRE_X64='http://mirr2.crystal-launcher.pl/jre/jre-8u181-linux-x64.tar.gz'

ICON='http://main.crystal-launcher.pl/releases/icon.png'

LAUNCHER_SCRIPT='https://raw.githubusercontent.com/leszczu8023/CrystalLauncher-LinuxScript/master/crystallauncher.sh'

LAUNCHER_JAR='http://main.crystal-launcher.pl/releases/other/CrystalLauncher.jar'
ACTIVATOR="[Desktop Entry]\n
Name=Crystal Launcher\n
GenericName=CrystalLauncher\n
Comment=A Minecraft modpack launcher\n
Exec=$INSTALL_DIR/launcher.sh\n
Icon=$INSTALL_DIR/icon.png\n
Terminal=false\n
Type=Application\n
Categories=Game;\n"

JAVA_VERSION='1.8.0_181'
DEBUG=0

export JAVA_HOME=$INSTALL_DIR/runtime/jre$JAVA_VERSION
export PATH=$JAVA_HOME/bin:$PATH

function osType {
	case `uname` in
		Linux)
			LINUX=1
			which yum > /dev/null && { echo centos; return; }
			which zypper > /dev/null  && { echo opensuse; return; }
			which pacman > /dev/null  && { echo archlinux; return; }
			which apt-get > /dev/null  && { echo debian; return; }
			;;
		*)
			LINUX=0
			;;
	esac
	if [ $LINUX -ne 1 ]
	then
		echo "This Crystal Launcher version is designed for running only on Linux operating systems..."
		exit
	fi
}

function notImplemented {
	echo "Distro not implemented or not fully checked... Some things may not work propertly!"
}

function aptInstaIfNe {
	if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0  ];
	then
		sudo apt -y install $1;
	fi;
}

function setupDebian {
	echo "Checking APT packages... Please enter root password if needed"
	aptInstaIfNe libgtk2.0-0;
}

function distroSpecSetup {
	case `osType` in
		centos)
			echo `notImplemented`;
			;;
		opensuse)
			echo 'nothing to do with packages this time :)'
			;;
		archlinux)
			echo `notImplemented`;
			;;
		debian)
			setupDebian;
			;;
		*)
			notImplemented;
			;;
	esac
}

function installCl {
	echo "Crystal Launcher installation script v1.0";
	if [ -e $INSTALL_DIR ];
	then
		echo "Removing old directory...";
		rm -rf $INSTALL_DIR;
	fi;

	mkdir -p $INSTALL_DIR;
	mkdir -p $INSTALL_DIR/runtime;
	mkdir -p $INSTALL_DIR/.tmp
	mkdir -p $INSTALL_DIR/bin
	
	MACHINE_TYPE=`uname -m`
	if [ ${MACHINE_TYPE} == 'x86_64' ];
	then
		echo "Downloading 64-bit Java $JAVA_VERSION runtime...";
		echo "";
		wget $JRE_X64 -O $INSTALL_DIR/.tmp/runtime.tar.gz
		if [ $? -ne 0 ]; then echo "Download runtime failed!!!"; exit; fi;
		echo "";
	elif [ ${MACHINE_TYPE} == 'i586' ];
	then
		echo "Downloading 32-bit Java $JAVA_VERSION runtime...";
		echo "";
		wget $JRE_I586 -O $INSTALL_DIR/.tmp/runtime.tar.gz
		if [ $? -ne 0 ]; then echo "Download runtime failed!!!"; exit; fi;
		echo "";
	else 
		echo "Unsupported architecture ${MACHINE_TYPE}...";
		echo "";
		exit;
	fi;

	echo "Extracting...";
	tar xzf $INSTALL_DIR/.tmp/runtime.tar.gz -C $INSTALL_DIR/runtime
	
	$JAVA_HOME/bin/java -version 2> /dev/null
	ERROR=$?
	if [ $ERROR -ne 0 ];
	then
		echo "Process launch failed! Check this message...";
		$JAVA_HOME/bin/java -version
		exit
	else
		echo "Download latest launcher bootstrap..."
		wget $LAUNCHER_JAR -O $INSTALL_DIR/bin/bootstrap.jar
		if [ $? -ne 0 ]; then echo "Download launcher failed!!!"; exit; fi;
	fi;

	echo "$INSTALL_DIR/bin" > ~/.crystalinst
	
	wget $ICON -O $INSTALL_DIR/icon.png
	
	wget $LAUNCHER_SCRIPT -O $INSTALL_DIR/launcher.sh
	if [ $? -ne 0 ]; then echo "Download launcher failed!!!"; exit; fi;
	
	chmod 775 $INSTALL_DIR/launcher.sh
	
	mkdir -p ~/.local/share/applications
	
	echo -e $ACTIVATOR > ~/.local/share/applications/CrystalLauncher.desktop
	update-desktop-database ~/.local/share/applications
	
	distroSpecSetup

	echo `date` > $INSTALL_DIR/installFlag
}

function runCrystal {
    	if [ ! -f $INSTALL_DIR/bin/launcher.jar ];
		then
			touch $INSTALL_DIR/bin/launcher.jar;
		fi;
		
		if [ $DEBUG -ne 0 ]; then
			(cd $INSTALL_DIR && exec $JAVA_HOME/bin/java -jar $INSTALL_DIR/bin/bootstrap.jar $@)
		else
			(cd $INSTALL_DIR && exec $JAVA_HOME/bin/java -jar $INSTALL_DIR/bin/bootstrap.jar $@) > /dev/null
		fi
}

case "$1" in
	"--reinstall")
		installCl;
		runCrystal;
		exit
		;;
	"--uninstall")
		rm -rf $INSTALL_DIR;
		rm ~/.local/share/applications/CrystalLauncher.desktop
		update-desktop-database ~/.local/share/applications
		exit
		;;
	"--force-update")
		rm -rf $INSTALL_DIR/bin/lib;
		echo "" > $INSTALL_DIR/bin/launcher.jar;
		;;
	"--install-only")
		installCl;
		exit
		;;
	"--clean-cache")
		rm -rf $INSTALL_DIR/bin/cache
		rm -rf $INSTALL_DIR/bin/Downloads
		;;
	"--debug")
		DEBUG=1
		;;
	"--help")
		echo "Usage: $0 --[debug|reinstall|uninstall|install-only|clean-cache|force-update]"
		exit
esac
		
if [ -f $INSTALL_DIR/installFlag ] && [ -f $INSTALL_DIR/bin/bootstrap.jar ];
then
	runCrystal;
else
	installCl;
	runCrystal;
fi;
