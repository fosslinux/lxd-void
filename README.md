# lxd-void

`lxd-void` creates a lxd image of void linux, as there is no void linux image
in the main image repository.

It works on non-voidlinux Linux distributions.

## Preresiquites

- bash
- coreutils
- sed
- grep
- wget
- tar
- lxd (not lxc)

## Options

- `-l musl|glibc`: choose which libc to use. By default, glibc is used.
- `-m mirror`: choose a mirror to use. This string is not checked so if it is
             incorrect then wget will fail. By default, the official mirror is
             used; http://alpha.de.repo.voidlinux.org.
- `-a architecture`: by default, this uses `uname -m`. If this is incorrect,
                   you can manully set the architecture.
- `-n alias`: this chooses the alias for the image, ie what is used when you
            create the container. The default is void-libc:date.
