desktop_config = configuration_data()
desktop_config.set('EXEC_PATH', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name())
configure_file (
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + 'desktop',
    configuration: desktop_config,
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
) 

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)