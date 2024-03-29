#!/usr/bin/env bash

# default variables
libc="glibc"
mirror="http://alpha.de.repo.voidlinux.org"
architecture="$(uname -m)"
unix_time="$(date +%s)"

# constants
METADATA="metadata.yaml"
ROOTFS="void-rootfs.tar.xz"
LXD_ROOTFS="rootfs.tar.xz"

# this is hardcoded only because the current/ link is broken
# if there is a easy dynamic solution please open an issue
LATEST="20190526"

# colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

# functions
usage() {
    echo "Usage: $0 [-l <musl|glibc>] [-m <mirror>] [-a <architecture>] [-n <alias>]" 1>&2
    exit 1
}

_ok() {
    printf "${GREEN}OK${NORMAL}\n"
}

_fail() {
    printf "${RED}FAILED${NORMAL}\n"
    exit 1
}

# cleanup from potential previous runs
printf "Clean up from (potential) previous runs of this script: "
{
    rm -rf rootfs/ metadata.tar ${LXD_ROOTFS}
} > /dev/null 2>&1 && _ok || _fail

# option parsing
while getopts ":l:m:a:n:" o ; do
    case "${o}" in
        l)
            libc=${OPTARG}
            [ "${libc}" != "musl" ] && [ "${libc}" != "glibc" ] && usage
            ;;
        m)
            mirror=${OPTARG}
            ;;
        a)
            architecture=${OPTARG}
            ;;
        n)
            alias=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# change values in metadata.yaml
printf "Change values in metadata.yml: "
{
    sed -i "s/ARCHITECTURE/${architecture}/g" ${METADATA}
    sed -i "s/LIBC/${libc}/g" ${METADATA}
    sed -i "s/CREATED/${unix_time}/g" ${METADATA}
} > /dev/null 2>&1 && _ok || _fail

# download rootfs
if [ ! -f ${ROOTFS} ] ; then
    printf "Download rootfs: "
    {
        wget -O ${ROOTFS} "${mirror}/live/${LATEST}/void-${architecture}-ROOTFS-${LATEST}.tar.xz"
    } > /dev/null 2>&1 && _ok || _fail
fi

printf "Modify rootfs: "
mkdir rootfs
cd rootfs
tar xpf ../${ROOTFS}
ln -s /etc/sv/dhcpcd-eth0 etc/runit/runsvdir/current/ # correct!
tar cJpf ../${LXD_ROOTFS} *
cd ..
_ok

# compress metadata
printf "Compress metadata: "
{
    tar cf metadata.tar ${METADATA} templates/
} > /dev/null 2>&1 && _ok || _fail

# make an alias if it wasn't specified on command line
aliasFallback="void-${libc}"
alias=${alias:-${aliasFallback}}

# we want to avoid having to gain privileges when running lxd
# if this is running as root, or the user is in the lxd group, then we do not
# need to gain privileges
# else, fall back to sudo

_lxd() {
    if (id -nG | grep -qw "lxd") || [ $(id -u) -eq 1 ] ; then
        lxc "$@"
    else
        sudo lxc "$@"
    fi
}

# import the image we've made
printf "Import image: "
{
    _lxd image import metadata.tar ${LXD_ROOTFS} --alias ${alias}
} > /dev/null 2>&1 && _ok || _fail
