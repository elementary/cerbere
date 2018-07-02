files = files(
    'Cerbere.vala',
    'ProcessWrapper.vala',
    'SessionManager.vala',
    'SettingsManager.vala',
    'Watchdog.vala'
)

dependencies = [
    dependency('gee-0.8'),
    dependency('gio-2.0'),
    dependency('glib-2.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false),
]

executable(
    meson.project_name(),
    files,
    dependencies: dependencies,
    install: true,
    install_dir: install_path
)
