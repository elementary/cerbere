# Cerbere

## Building and Installation

You'll need the following dependencies:

* cmake
* libgee-0.8-dev
* libglib2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `cerbere

    sudo make install
    cerbere
