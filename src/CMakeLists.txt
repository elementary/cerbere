# Vala stuff
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)

# pkgconfig, real C code
find_package(PkgConfig)

set(VALA_DEPS glib-2.0 gio-2.0 gee-1.0)

pkg_check_modules(DEPS REQUIRED ${VALA_DEPS})
set(CFLAGS ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER})
set(LIB_PATHS ${DEPS_LIBRARY_DIRS})
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})

set(EXEC_NAME ${CMAKE_PROJECT_NAME})

vala_precompile(VALA_C ${EXEC_NAME}
    Cerbere.vala
    SettingsManager.vala
    SessionManager.vala
    Watchdog.vala
    ProcessWrapper.vala
  PACKAGES
    ${VALA_DEPS}
  OPTIONS
    --target-glib=2.32 # Remember to keep this updated.
)

add_executable(${EXEC_NAME} ${VALA_C})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})
install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
