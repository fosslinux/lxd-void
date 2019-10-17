#!/usr/bin/env bash

libc="glibc"
mirror="http://alpha.de.repo.voidlinux.org"
architecture="$(uname -m)"
unix_time="$(date +%s)"

METADATA="metadata.yaml"

# this is hardcoded only because the current/ link is broken
# if there is a easy dynamic solution please open an issue
latest="20190526"

usage() {
    echo "Usage: $0 [-l <musl|glibc>] [-m <mirror>] [-a <architecture>] [-n <alias>]" 1>&2
    exit 1
}

# cleanup from potential previous runs
rm -f rootfs.tar.xz metadata.tar

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
    shift $((OPTIND-1))
done

# change values in metadata.yaml
sed -i "s/ARCHITECTURE/${architecture}/g" ${METADATA}
sed -i "s/LIBC/${libc}/g" ${METADATA}
sed -i "s/CREATED/${unix_time}/g" ${METADATA}

# download rootfs
wget -O rootfs.tar.xz "${mirror}/live/${latest}/void-${architecture}-ROOTFS-${latest}.tar.xz"

# compress metadata
tar cf metadata.tar ${METADATA} template/

# make an alias if it wasn't specified on command line
aliasFallback="void-${libc}:${latest}"
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
_lxd image import metadata.tar rootfs.tar.xz --alias ${alias}
