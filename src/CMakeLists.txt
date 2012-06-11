# Vala stuff

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.14" MINIMUM)
include(ValaPrecompile)

# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED glib-2.0 gio-2.0 gee-1.0)
set(CFLAGS
	${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(LIB_PATHS
	${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})


add_definitions(${CFLAGS})
vala_precompile (
VALA_C
    Cerbere.vala
    SettingsManager.vala
    Watchdog.vala
    ProcessInfo.vala
PACKAGES
    glib-2.0
    gio-2.0
    gee-1.0
OPTIONS
    ${ADD_OPTIONS})

add_executable(cerbere
    ${VALA_C} )

target_link_libraries(cerbere ${DEPS_LIBRARIES})

install(TARGETS cerbere RUNTIME DESTINATION bin)
