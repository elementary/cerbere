#! /usr/bin/env python
# encoding: utf-8
# Copyright (c) 2010: GPL
# Author: SjB <steve@sagacity.ca>
#

VERSION = '0.0.1'
APPNAME = 'cerbere'

top = '.'
out = 'build'

def options(opt):
    opt.load('compiler_c')
    opt.load('vala')

def configure(conf):
    conf.load('compiler_c vala')
    conf.check_vala(min_version=(0,10,0))

    conf.check_cfg(package = 'glib-2.0',
            uselib_store = 'GLIB',
            atleast_version = '2.22.0',
            mandatory = 1,
            args = '--cflags --libs')
    
    conf.check_cfg(package = 'gio-2.0',
            uselib_store = 'GIO',
            atleast_version = '2.26.0',
            mandatory = 1,
            args = '--cflags --libs')

    conf.check_cfg(package = 'gee-1.0',
            uselib_store = 'GEE',
            atleast_version = '0.5.3',
            args = '--cflags --libs')

    conf.define ('GETTEXT_PACKAGE', APPNAME)

def build(bld):
    src = ['cerbere.vala']

    task = bld.program(target = 'cerbere',
            packages = 'glib-2.0 gee-1.0 gio-2.0',
            uselib = 'GLIB GIO GEE',
            source = src);
    task.vapi_dirs = ['.',]
    
    bld.install_files('${PREFIX}/share/cerbere', '/cerbere.session');
    bld.install_files('/usr/share/applications', '/cerbere.desktop');
