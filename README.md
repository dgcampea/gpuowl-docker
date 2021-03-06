# gpuowl container image

Container image build script and utilities for using and deploying
gpuowl.

# Table of Contents
  - [Installing](#installing)
      - [Pulling the image](#pulling-the-image)
      - [Note: SELinux enabled systems](#note-selinux-enabled-systems)
  - [Usage](#usage)
      - [Podman/Docker parameters](#podmandocker-parameters)
      - [Drop-in replacement mode (console
        usage)](#drop-in-replacement-mode-console-usage)
      - [Daemon mode](#daemon-mode)
  - [Building locally](#building-locally)
      - [Dependencies](#dependencies)
      - [Makefile recipes](#makefile-recipes)
      - [Makefile variables](#makefile-variables)
  - [License](#license)

## Installing

### Pulling the image

Pull the latest available image with:

``` sh
$ podman pull ghcr.io/dgcampea/gpuowl:latest
```

To pull a specific gpuowl image, list available tags with
`podman-search`:

``` sh
$ podman search --list-tags ghcr.io/dgcampea/gpuowl
NAME                     TAG
ghcr.io/dgcampea/gpuowl  v7.2-69-g23c14a1
ghcr.io/dgcampea/gpuowl  v7.2-70-g212618e
ghcr.io/dgcampea/gpuowl  latest

# pull v7.2-70-g212618e
$ podman pull ghcr.io/dgcampea/gpuowl:v7.2-70-g212618e
```

### Note: SELinux enabled systems

For SELinux enabled systems, two modules are required:

  - base\_container.cil (provided by `udica`)
  - gpuowl.cil (located at `extras/gpuowl.cil`)

If `udica` package is not available for your distribution, you can
download the required file from:
<https://github.com/containers/udica/blob/master/udica/templates/base_container.cil>

#### With `udica`:

``` sh
$ sudo semodule -i extras/gpuowl_container.cil /usr/share/udica/templates/base_container.cil
```

#### Without `udica`

``` sh
$ curl -O https://raw.githubusercontent.com/containers/udica/master/udica/templates/base_container.cil
$ sudo semodule -i extras/gpuowl_container.cil base_container.cil
```

## Usage

### Podman/Docker parameters

Required podman/docker parameters:

  - `--device=/dev/kfd`
  - `--device=/dev/dri`
  - volume or bind mount at `/in` for gpuowl data (worktodo.txt, logs,
    etc.)

Example:

``` sh
mkdir $HOME/gpuowl_container

# with SELinux
$ podman run --rm -it --name gpuowl --device=/dev/kfd --device=/dev/dri \
    --security-opt label=type:gpuowl_container.process \
    -v "$HOME/gpuowl_container":/in:Z gpuowl:latest -h

# without SELinux
$ podman run --rm -it --name gpuowl --device=/dev/kfd --device=/dev/dri \
    -v "$HOME/gpuowl_container":/in gpuowl:latest -h
```

### Drop-in replacement mode (console usage)

`gpuowl-wrapper.sh` attempts to be a near drop-in replacement for
gpuowl.  
Note: The wrapper will attempt to mount the current working directory
(`$PWD`) into the container, potentially conflicting with any
*filesystem related arguments* (such as `-dir`, `-pool` and `-tmpDir`).

### Daemon mode

Prepare your system with (replace *\<user\>* with the user that will run
`gpuowl`):

``` sh
$ sudo setsebool -P container_manage_cgroup on      # for SELinux systems
$ sudo loginctl enable-linger <user>
$ mkdir "$HOME/gpuowl_container"
$ cp extras/daemon/gpuowl.service ~/.config/systemd/user/gpuowl.service
$ systemctl enable --user gpuowl@default.service
```

In this mode, `gpuowl` will read and save its data to
`~/gpuowl_container/instance-default`.  
Running more than one instance can be done by changing the argument
after `gpuowl@` (ex: `gpuowl@nano.service`) and creating a directory
`instance-nano` with *config.txt* under `~/gpuowl_container/`.

#### Automatic downclocking support (requires `rocm-smi` on system):

Grant your user sudo powers for `rocm-smi` by adding this to your
*/etc/sudoers* file:

    <user> ALL=(root) NOPASSWD: /usr/bin/rocm-smi

Afterwards, create an override config for the service unit with:

``` sh
$ install -Dm644 -t ~/.config/systemd/user/gpuowl@.service.d extras/daemon/override.conf
$ systemctl daemon-reload --user
```

## Building locally

### Dependencies

  - buildah

Invoke `make` to build container image.  
Variables can be overridden with `make VAR=value VAR2=value ...`.  
By default, the built image is tagged as *gpuowl:\<gpuowl\_version\>*
and *gpuowl:latest*.

### Makefile recipes

#### image

*default target*

Build gpuowl container image.

#### install

Install gpuowl-wrapper.sh to `~/.local/bin`.

### Makefile variables

#### CHECKOUT

*default = ? HEAD ?*

Checkout at the commit/branch specified.  
Upstream repo: <https://github.com/preda/gpuowl>

#### ROCM\_VER

*default = ? latest ?*

Set ROCm version for base image.  
If set, image name will be set to gpuowl-\<ROCM\_VER\>.

#### LATEST

*default = ? 1 ?*

Tag the built image with :latest.

## License

Unless stated otherwise, all content from this repo is placed under *CC0
1.0 Universal* when applicable.
