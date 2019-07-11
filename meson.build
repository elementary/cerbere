project(
    'io.elementary.cerbere',
    'vala', 'c',
    version: '2.5.0'
)

install_path = join_paths(get_option('prefix'), get_option('libexecdir'))
subdir('data')
subdir('src')

meson.add_install_script('meson/post_install.py')
