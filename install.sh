# Constants
# INSTALLDIR='/usr/local/src'
DIR_TMP='/tmp/svr-setup'
FLLOGDIR='/var/log/fluidlemp'

# check to see if DIR_TMP and FLORIDIR exist
if [ ! -d "$DIR_TMP" ]; then
    mkdir -p $DIR_TMP
fi

if [ ! -d "$FLLOGDIR" ]; then
    mkdir -p $FLLOGDIR
fi
