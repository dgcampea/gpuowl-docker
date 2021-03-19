# gpuowl Dockerfile

Dockerfile and utilities for using and deploying gpuowl.

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
      - [Makefile variables](#makefile-variables)
  - [License](#license)

## Installing

### Pulling the image

Pull with:

    podman pull ghcr.io/dgcampea/gpuowl:latest

### Note: SELinux enabled systems

For SELinux enabled systems, `udica` package is recommended.  
If the package is not available for your distribution, you can download
the required file from:
<https://github.com/containers/udica/blob/master/udica/templates/base_container.cil>

#### With `udica`:

    sudo semodule -i gpuowl_container.cil /usr/share/udica/templates/base_container.cil

#### Without `udica`

    curl -O https://raw.githubusercontent.com/containers/udica/master/udica/templates/base_container.cil 
    sudo semodule -i gpuowl_container.cil base_container.cil

## Usage

### Podman/Docker parameters

Required podman/docker parameters:

  - `--device=/dev/kfd`
  - `--device=/dev/dri`
  - volume or bind mount at `/in` for gpuowl data (worktodo.txt, logs,
    etc.)

Example:

    mkdir $HOME/gpuowl_container
    
    # with SELinux
    podman run --rm -it --name gpuowl --device=/dev/kfd --device=/dev/dri \
        --security-opt label=type:gpuowl_container.process \
        -v "$HOME/gpuowl_container":/in:Z gpuowl:latest -h
    
    # without SELinux
    podman run --rm -it --name gpuowl --device=/dev/kfd --device=/dev/dri \
        -v "$HOME/gpuowl_container":/in gpuowl:latest -h

See *gpuowl\_wrapper.sh* and *Dockerfile* for more details.

### Drop-in replacement mode (console usage)

`gpuowl-wrapper.sh` attempts to be a near drop-in replacement for
gpuowl.  
Note: The wrapper will attempt to mount the current working directory
(`$PWD`) into the container, potentially conflicting with any
*filesystem related arguments* (such as `-dir`, `-pool` and `-tmpDir`).

### Daemon mode

Prepare your system with (replace *\<user\>* with the user that will run
`gpuowl`):

    sudo setsebool -P container_manage_cgroup on      # for SELinux systems
    sudo loginctl enable-linger <user>
    mkdir "$HOME/gpuowl_container"
    cp extras/gpuowl.service ~/.config/systemd/user/gpuowl.service
    systemctl enable --user gpuowl@default.service

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

    install -Dm644 -t ~/.config/systemd/user/gpuowl@.service.d extras/override.conf
    systemctl daemon-reload --user

## Building locally

Invoke `make` to build Dockerfile.  
Variables can be overridden with `make VAR=value VAR2=value ...`.  
By default, the built image is tagged as *gpuowl:COMMIT\_ID* and
*gpuowl:latest*.  
If`COMMIT` is specified, the image will not be tagged with *latest*.

### Makefile variables

#### COMMIT

*default = ? latest commit id at HEAD, generated when make is executed
?*

Set the image tag and checkout at the commit specified.  
If the latest commit id at HEAD isn’t retrievable, defaults to `HEAD`.  
Can be used to checkout specific commit ids or branches.  
Upstream repo: <https://github.com/preda/gpuowl>

## License

Unless stated otherwise, all content from this repo is placed under *CC0
1.0 Universal* when applicable.
