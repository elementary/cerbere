project(
    'io.elementary.cerbere',
    'vala', 'c',
    version: '0.2.3'
)

install_path = join_paths(get_option('prefix'), get_option('libexecdir'))
subdir('data')
subdir('src')

meson.add_install_script('meson/post_install.py')
