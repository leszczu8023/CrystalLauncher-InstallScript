#!/usr/bin/env bash

INSTALL_DIR=$HOME/.crystalLauncher

JRE_I586='http://mirr2.crystal-launcher.pl/jre/jre-8u181-linux-i586.tar.gz'
JRE_X64='http://mirr2.crystal-launcher.pl/jre/jre-8u181-linux-x64.tar.gz'

ICON='http://main.crystal-launcher.pl/releases/icon.png'

LAUNCHER_SCRIPT='https://raw.githubusercontent.com/leszczu8023/CrystalLauncher-InstallScript/master/crystallauncher.sh'

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

function runAsRoot {
	if [[ "`whoami`" == "root" ]]; then
		$*
	elif [[ -x "$(command -v sudo)" ]]; then
		sudo $*
	else
		su root -c "$*"
	fi
}

function downloadFile {
	#$1 - source URL
	#$2 - target location
    
	if [[ -x "$(command -v wget)" ]]; then
		wget "$1" -O "$2";
		if [[ $? -ne 0 ]]; then 
			echo "Downloading launcher failed!!!"; 
			exit 1; 
		fi;
	elif [[ -x "$(command -v curl)" ]]; then
		curl -L -o "$2" "$1";
		if [[ $? -ne 0 ]]; then 
			echo "Downloading launcher failed!!!"; 
			exit 1; 
		fi;
	else
    		echo "Unable to find wget and curl in system... Pleas install one of it..."
		exit 1; 
	fi
}


function osType {
	case `uname` in
		Linux)
			LINUX=1
			FBSD=0
			which yum > /dev/null && { echo centos; return; }
			which zypper > /dev/null  && { echo opensuse; return; }
			which pacman > /dev/null  && { echo archlinux; return; }
			which apt-get > /dev/null  && { echo debian; return; }
			;;
		FreeBSD)
			FBSD=1
			LINUX=0
			which pkg > /dev/null && { echo fbsdpkg; return; }
			;;
		*)
			FBSD=0
			LINUX=0
	esac
	
	if [[ "$LINUX" -ne 1 && "$FBSD" -ne 1 ]]; then
		echo "This Crystal Launcher version is designed for running only on Linux and FreeBSD operating systems..."
		exit 1
	fi
}

function notImplemented {
	echo "Distro not implemented or not fully checked... Some things may not work propertly!"
}

function aptInstaIfNe {
	if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0  ];
	then
		runAsRoot apt -y install $1;
	fi;
}

function pkgInstaIfNe {
	pkg info -Ix $1
	if [ "$?" -ne 0  ];
	then
		runAsRoot env ASSUME_ALWAYS_YES=YES pkg install $1;
	fi;
}

function setupDebian {
	echo "Checking APT packages... Please enter root password if needed"
	aptInstaIfNe libgtk2.0-0;
}

function setupFreeBSD {
	echo "Checking packages... Please enter root password if needed"
	pkgInstaIfNe openjdk8-jre
	pkgInstaIfNe openjfx8-devel
	pkgInstaIfNe minecraft-client
	
	echo "customjvmdir.path=/usr/local/share/minecraft-client/minecraft-runtime">"$INSTALL_DIR/bin/config.prop"
	echo "customjvmdir.use=true">>"$INSTALL_DIR/bin/config.prop"
}

function distroSpecSetup {
	OS=`osType`
	echo "Detected OS: $OS"
	case "$OS" in
		centos)
			notImplemented;
			;;
		opensuse)
			echo 'nothing to do with packages this time :)'
			;;
		archlinux)
			notImplemented;
			;;
		debian)
			setupDebian;
			;;
		fbsdpkg)
			setupFreeBSD;
			;;
		*)
			notImplemented;
			;;
	esac
}

function setupRuntime {
	export JAVA_HOME=$INSTALL_DIR/runtime/jre$JAVA_VERSION
	export PATH=$JAVA_HOME/bin:$PATH

	MACHINE_TYPE=`uname -m`
	[[ $MACHINE_TYPE = "amd64" ]] && MACHINE_TYPE=x86_64 # Fix dla ArchLinuxa i pochodnych
	
	if [[ ${MACHINE_TYPE} == 'x86_64' ]];
	then
		echo "Downloading 64-bit Java $JAVA_VERSION runtime...";
		echo "";
		downloadFile "$JRE_X64" "$INSTALL_DIR/.tmp/runtime.tar.gz"
		echo ""
	elif [[ ${MACHINE_TYPE} == 'i586' ]];
	then
		echo "Using 32Bit computer is not recommended, upgrade PC to 64Bit CPU or install 64Bit OS"
		echo "Downloading 32-bit Java $JAVA_VERSION runtime...";
		echo "";
		downloadFile "$JRE_I586" "$INSTALL_DIR/.tmp/runtime.tar.gz"
		echo ""
	else 
		echo "Unsupported architecture ${MACHINE_TYPE}...";
		echo "";
		exit 1
	fi;

	echo "Extracting...";
	tar xzf "$INSTALL_DIR/.tmp/runtime.tar.gz" -C "$INSTALL_DIR/runtime"
	
	rm "$INSTALL_DIR/.tmp/runtime.tar.gz"
	
	"$JAVA_HOME/bin/java" -version 2> /dev/null
	ERROR=$?
	if [ $ERROR -ne 0 ];
	then
		echo "Process launch failed! Check this message...";
		"$JAVA_HOME/bin/java" -version
		exit 1
	fi;
}

function installCl {
	echo "Crystal Launcher installation script";
	if [[ -e $INSTALL_DIR ]];
	then
		echo "Removing old directory...";
		rm -rf $INSTALL_DIR;
	fi;

	mkdir -p "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR/runtime"
	mkdir -p "$INSTALL_DIR/.tmp"
	mkdir -p "$INSTALL_DIR/bin"
	
	distroSpecSetup
	
	if [[ "`uname`" == 'Linux' ]]; then
		echo "Installing portable Java environment..."
		setupRuntime
	fi
	
	echo "Download latest launcher bootstrap..."
	downloadFile "$LAUNCHER_JAR" "$INSTALL_DIR/bin/bootstrap.jar"	
	downloadFile "$ICON" "$INSTALL_DIR/icon.png"	
	downloadFile "$LAUNCHER_SCRIPT" "$INSTALL_DIR/launcher.sh"
	
	echo "$INSTALL_DIR/bin" > "$HOME/.crystalinst"	
	
	chmod 775 "$INSTALL_DIR/launcher.sh"
	
	mkdir -p "$HOME/.local/share/applications"
	
	echo -e $ACTIVATOR > "$HOME/.local/share/applications/CrystalLauncher.desktop"
	
	if [[ -f "`which update-desktop-database `" ]]; then
		update-desktop-database "$HOME/.local/share/applications";
	fi;
	
	echo `date` > "$INSTALL_DIR/installFlag"
}

function runCrystal {
	if [[ ! -f "$INSTALL_DIR/bin/launcher.jar" ]]; then
		touch "$INSTALL_DIR/bin/launcher.jar";
	fi;
		
	OS=`osType`
	case "$OS" in
		fbsdpkg)
			if [[ $DEBUG -ne 0 ]]; then
				(cd "$INSTALL_DIR" && exec java -jar "$INSTALL_DIR/bin/bootstrap.jar")
			else
				(cd "$INSTALL_DIR" && exec java -jar "$INSTALL_DIR/bin/bootstrap.jar") > /dev/null
			fi
			;;
		*)
			export JAVA_HOME=$INSTALL_DIR/runtime/jre$JAVA_VERSION
                	export PATH=$JAVA_HOME/bin:$PATH
			if [[ $DEBUG -ne 0 ]]; then
				(cd "$INSTALL_DIR" && exec "$JAVA_HOME/bin/java" -jar "$INSTALL_DIR/bin/bootstrap.jar")
			else
				(cd "$INSTALL_DIR" && exec "$JAVA_HOME/bin/java" -jar "$INSTALL_DIR/bin/bootstrap.jar") > /dev/null
			fi
			;;
	esac
}

case "$1" in
	"--reinstall")
		installCl;
		runCrystal;
		exit
		;;
	"--uninstall")
		rm -rf "$INSTALL_DIR"
		rm "$HOME/.local/share/applications/CrystalLauncher.desktop"
		update-desktop-database "$HOME/.local/share/applications"
		exit
		;;
	"--force-update")
		rm -rf "$INSTALL_DIR/bin/lib"
		echo "" > "$INSTALL_DIR/bin/launcher.jar"
		;;
	"--install-only")
		installCl;
		exit
		;;
	"--clean-cache")
		rm -rf "$INSTALL_DIR/bin/cache"
		rm -rf "$INSTALL_DIR/bin/Downloads"
		;;
	"--debug")
		DEBUG=1
		;;
	"--help")
		echo "Usage: $0 --[debug|reinstall|uninstall|install-only|clean-cache|force-update]"
		exit 0
		;;
esac
		
if [ -f "$INSTALL_DIR/installFlag" ] && [ -f "$INSTALL_DIR/bin/bootstrap.jar" ];
then
	runCrystal;
else
	installCl;
	runCrystal;
fi;
