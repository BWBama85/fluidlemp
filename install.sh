#!/bin/bash
source inc/helpers/variables.inc
source inc/helpers/logger.sh
# Constants
# INSTALLDIR='/usr/local/src'
DIR_TMP='/tmp/svr-setup'
FLLOGDIR='/var/log/fluidlemp'

# Setup Colours
color_green='\E[32;40m'
color_yellow='\E[33;40m'
color_red='\E[31;40m'

if [ ! -d "$DIR_TMP" ]; then
    mkdir -p $DIR_TMP
fi

# Ensure script is run as root
if [ "$(id -u)" != 0 ]; then
    log_message "This script must be run as root." "$color_red" >&2
    exit 1
fi

# Update package lists and create necessary directories
apt-get update
mkdir -p "$FLLOGDIR" "$DIR_TMP"

# Install necessary packages and configure services
install_package build-essential
install_package sysstat
install_package ntp
sed -i 's|10|5|g' /etc/cron.d/sysstat
echo "* * * * * root /usr/lib/sa/sa1 1 1" >/etc/cron.d/cmsar
systemctl restart sysstat.service
systemctl enable sysstat.service
systemctl enable --now ntp

# Remove conflicting packages
purge_package 'mysql-server'
purge_package 'mariadb-server'
purge_package 'mariadb-client'
apt-get -y autoremove
apt-get -y clean

# Function to check if 'sar' is available
sar_call() {
    if type sar &>/dev/null; then
        /usr/lib/sa/sa1 1 1
    else
        log_message "sar not found, skipping." "$color_yellow"
    fi
}

# Function to install PCRE if not present
source_pcreinstall() {
    if [[ "$($PCRE_CONFIG --version 2>&1 | grep -q "${ALTPCRE_VERSION}")" != '0' ]]; then
        cd "$DIR_TMP" || exit
        log_message "Downloading $ALTPCRELINKFILE ..." "$color_yellow"
        wget -c --progress=bar "$ALTPCRELINK" --tries=3 || { log_message "Error: Download failed." "$color_red" && exit; }
        tar xzf "$ALTPCRELINKFILE" || { log_message "Error: Extraction failed." "$color_red" && exit; }
        cd "pcre-${ALTPCRE_VERSION}" || exit
        ./configure --enable-utf8 --enable-unicode-properties --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --enable-jit
        make && make install
        $PCRE_CONFIG --version
    fi
}

if [[ $(
    dpkg -l | grep -w "nmap\|netcat" >/dev/null 2>&1
    echo $?
) != '0' ]]; then
    time apt-get -y install nmap netcat
    sar_call
fi

# Main execution
source_pcreinstall
