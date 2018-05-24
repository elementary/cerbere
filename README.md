# Cerbere

## Building and Installation

You'll need the following dependencies:

* libgee-0.8-dev
* libglib2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `cerbere`

    sudo ninja install
    cerbere
